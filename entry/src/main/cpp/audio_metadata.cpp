/*
 * Copyright 2026 何宇翔
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "audio_metadata.h"

#include <fstream>
#include <vector>
#include <cstring>
#include <cctype>
#include <cstdint>

namespace {

// P2-6（static_assert）：MP4 largesize 依赖 64 位 size_t，固化前提防止 32 位 ABI 截断
// （当前目标 phone/arm64 为 64 位不受影响，此处为防御性固化）。
static_assert(sizeof(size_t) >= 8, "64-bit size_t required for MP4 largesize");

// ===== MPEG 音频帧头常量表（P2-5 二次校验 / P2-3 spf 共用） =====
// 码率表 [版本][层][码率索引]（kbps）；层序：0=Layer I / 1=Layer II / 2=Layer III
static const int kBrTable[3][3][16] = {
    { {0,32,64,96,128,160,192,224,256,288,320,352,384,416,448,0},   // MPEG1 Layer I
      {0,32,48,56,64,80,96,112,128,160,192,224,256,320,384,0},       // MPEG1 Layer II
      {0,32,40,48,56,64,80,96,112,128,160,192,224,256,320,0} },      // MPEG1 Layer III
    { {0,32,48,56,64,80,96,112,128,144,160,176,192,224,256,0},
      {0,8,16,24,32,40,48,56,64,80,96,112,128,144,160,0},
      {0,8,16,24,32,40,48,56,64,80,96,112,128,144,160,0} },
    { {0,32,48,56,64,80,96,112,128,144,160,176,192,224,256,0},
      {0,8,16,24,32,40,48,56,64,80,96,112,128,144,160,0},
      {0,8,16,24,32,40,48,56,64,80,96,112,128,144,160,0} }
};
static const int kSrTable[3][3] = { {44100,48000,32000}, {22050,24000,16000}, {11025,12000,8000} };

// 解析单个 MPEG 帧头；返回 false 表示 i 处不是合法帧头（P2-5 帧同步二次校验用）。
// 合法时输出版本/层/码率索引/采样率索引/声道模式/帧长（字节）。
bool parseMpegFrameHeader(const std::vector<unsigned char>& buf, size_t i, int& ver, int& layer,
                          int& brIdx, int& srIdx, int& chanMode, int& frameLen) {
    if (i + 4 > buf.size()) {
        return false;
    }
    const unsigned char v1 = buf[i + 1];
    const int verBits = (v1 >> 3) & 0x03;   // 3=MPEG1, 2=MPEG2, 0=MPEG2.5, 1=保留
    const int layerBits = (v1 >> 1) & 0x03; // 3=LayerI, 2=LayerII, 1=LayerIII, 0=保留
    // 高 11 位同步（0xFFE0）+ 排除保留版本/保留层（P1-4 允许合法 MPEG 2.5）
    if (buf[i] != 0xFF || (v1 & 0xE0) != 0xE0 || verBits == 1 || layerBits == 0) {
        return false;
    }
    ver = verBits;
    layer = layerBits;
    brIdx = (buf[i + 2] >> 4) & 0x0F;
    srIdx = (buf[i + 2] >> 2) & 0x03;
    chanMode = (buf[i + 3] >> 6) & 0x03;
    if (brIdx < 1 || brIdx > 14 || srIdx > 2) { // 15=自由格式（码率表为 0）、srIdx==3 为保留
        return false;
    }
    const int verIdx = (ver == 3) ? 0 : (ver == 2 ? 1 : 2);
    const int layerIdx = 3 - layer; // P1-3：3(I)→0, 2(II)→1, 1(III)→2
    const int bitrate = kBrTable[verIdx][layerIdx][brIdx];
    const int sr = kSrTable[verIdx][srIdx];
    if (bitrate <= 0 || sr <= 0) {
        return false;
    }
    const int padding = (buf[i + 2] >> 1) & 0x01;
    if (layer == 3) { // Layer I：帧长 = (12*bitrate/sr + padding) * 4
        frameLen = (12 * bitrate * 1000 / sr + padding) * 4;
    } else if (layer == 1 && ver != 3) { // Layer III @ MPEG2/2.5：72 系数
        frameLen = 72 * bitrate * 1000 / sr + padding;
    } else { // Layer II（任意版本）/ Layer III @ MPEG1：144 系数
        frameLen = 144 * bitrate * 1000 / sr + padding;
    }
    return true;
}

// P2-3：每帧采样数显式区分 Layer（防御性显式化；Xing 探测已收窄到 Layer III，实际风险已低）
int spfForFrame(int ver, int layer) {
    if (layer == 3) {
        return 384;      // Layer I
    }
    if (layer == 2) {
        return 1152;     // Layer II
    }
    return (ver == 3) ? 1152 : 576; // Layer III：MPEG1=1152，MPEG2/2.5=576
}

bool readFile(const std::string& path, std::vector<unsigned char>& out, size_t maxSize = 0) {
    std::ifstream f(path, std::ios::binary);
    if (!f) {
        return false;
    }
    f.seekg(0, std::ios::end);
    std::streamoff sz = f.tellg();
    if (sz <= 0) {
        return false;
    }
    f.seekg(0, std::ios::beg);
    size_t readSize = (maxSize > 0 && static_cast<size_t>(sz) > maxSize)
        ? maxSize : static_cast<size_t>(sz);
    out.resize(readSize);
    f.read(reinterpret_cast<char*>(out.data()), static_cast<std::streamsize>(readSize));
    const std::streamsize got = f.gcount();
    if (got <= 0) {
        out.clear();
        return false;
    }
    out.resize(static_cast<size_t>(got));
    return true;
}

bool tagEq(const unsigned char* p, const char* tag) {
    return p[0] == static_cast<unsigned char>(tag[0]) &&
           p[1] == static_cast<unsigned char>(tag[1]) &&
           p[2] == static_cast<unsigned char>(tag[2]) &&
           p[3] == static_cast<unsigned char>(tag[3]);
}

// iTunes 版权符原子名（Latin-1 0xA9 + 3 字母），用显式数组避免 \x 转义贪婪解析
const char kNam[4] = { '\xa9', 'n', 'a', 'm' };
const char kART[4] = { '\xa9', 'A', 'R', 'T' };
const char kaART[4] = { 'a', 'A', 'R', 'T' };
const char kAlb[4] = { '\xa9', 'a', 'l', 'b' };
const char kDay[4] = { '\xa9', 'd', 'a', 'y' };

int syncsafeToInt(const unsigned char* p) {
    return (p[0] << 21) | (p[1] << 14) | (p[2] << 7) | p[3];
}

bool endsWith(const std::string& s, const char* suffix) {
    size_t sl = s.length();
    size_t su = std::strlen(suffix);
    if (sl < su) {
        return false;
    }
    return s.compare(sl - su, su, suffix) == 0;
}

// 去除首尾空白
std::string trimCopy(const std::string& s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    if (a == std::string::npos) {
        return "";
    }
    size_t b = s.find_last_not_of(" \t\r\n");
    return s.substr(a, b - a + 1);
}

// ===== FLAC：VORBIS_COMMENT 文本 + STREAMINFO 采样率/声道/时长 =====
AudioMetadata parseFlac(const std::vector<unsigned char>& buf) {
    AudioMetadata m;
    m.title = "";
    m.artist = "未知艺术家";
    m.album = "未知专辑";
    m.year = "";
    m.durationMs = 0;
    m.sampleRate = 44100;
    m.channels = 2;
    m.bitDepth = 0;
    m.codec = "flac";
    if (buf.size() < 4 || !(buf[0] == 'f' && buf[1] == 'L' && buf[2] == 'a' && buf[3] == 'C')) {
        return m;
    }
    size_t pos = 4;
    bool last = false;
    while (pos + 4 <= buf.size() && !last) {
        unsigned char b0 = buf[pos];
        last = (b0 & 0x80) != 0;
        unsigned char type = b0 & 0x7F;
        unsigned int len = (static_cast<unsigned int>(buf[pos + 1]) << 16) |
                           (static_cast<unsigned int>(buf[pos + 2]) << 8) |
                           static_cast<unsigned int>(buf[pos + 3]);
        pos += 4;
        if (pos + len > buf.size()) {
            break;
        }
        if (type == 0 && len >= 18) { // STREAMINFO
            unsigned int sr = (static_cast<unsigned int>(buf[pos + 10]) << 12) |
                              (static_cast<unsigned int>(buf[pos + 11]) << 4) |
                              ((static_cast<unsigned int>(buf[pos + 12]) >> 4) & 0x0F);
            unsigned int ch = ((static_cast<unsigned int>(buf[pos + 12]) >> 1) & 0x07) + 1;
            // 位深：byte12 最低 1 位 + byte13 高 4 位（共 5 位），+1 得真实位深
            unsigned int bps = ((static_cast<unsigned int>(buf[pos + 12]) & 0x01) << 4) |
                               ((static_cast<unsigned int>(buf[pos + 13]) >> 4) & 0x0F);
            uint64_t total = ((static_cast<uint64_t>(buf[pos + 13]) & 0x0F) << 32) |
                             (static_cast<uint64_t>(buf[pos + 14]) << 24) |
                             (static_cast<uint64_t>(buf[pos + 15]) << 16) |
                             (static_cast<uint64_t>(buf[pos + 16]) << 8) |
                             static_cast<uint64_t>(buf[pos + 17]);
            if (sr > 0) {
                m.sampleRate = static_cast<int>(sr);
                m.channels = static_cast<int>(ch);
                m.bitDepth = static_cast<int>(bps) + 1;
                m.durationMs = static_cast<int>(total * 1000 / sr);
            }
        } else if (type == 4 && len >= 8) { // VORBIS_COMMENT
            // 边界统一用「相对块内偏移 p < len」+ uint64 加法，杜绝 32 位回绕（P0-1 / P0-2）
            size_t p = 0;
            unsigned int vendorLen = static_cast<unsigned int>(buf[pos + p]) |
                                     (static_cast<unsigned int>(buf[pos + p + 1]) << 8) |
                                     (static_cast<unsigned int>(buf[pos + p + 2]) << 16) |
                                     (static_cast<unsigned int>(buf[pos + p + 3]) << 24);
            p += 4;
            if (static_cast<uint64_t>(p) + vendorLen > len) { // P0-1：vendor 串越界
                break;
            }
            p += vendorLen;
            if (p + 4 > len) {
                break;
            }
            unsigned int count = static_cast<unsigned int>(buf[pos + p]) |
                                 (static_cast<unsigned int>(buf[pos + p + 1]) << 8) |
                                 (static_cast<unsigned int>(buf[pos + p + 2]) << 16) |
                                 (static_cast<unsigned int>(buf[pos + p + 3]) << 24);
            p += 4;
            for (unsigned int i = 0; i < count; i++) {
                if (p + 4 > len) {
                    break;
                }
                unsigned int clen = static_cast<unsigned int>(buf[pos + p]) |
                                    (static_cast<unsigned int>(buf[pos + p + 1]) << 8) |
                                    (static_cast<unsigned int>(buf[pos + p + 2]) << 16) |
                                    (static_cast<unsigned int>(buf[pos + p + 3]) << 24);
                p += 4;
                if (static_cast<uint64_t>(p) + clen > len) { // P0-2：clen 回绕检查 100% 失效修复
                    break;
                }
                std::string comment;
                if (clen > 0) { // 避免 &buf[pos + p] == &buf[pos + len] 的 UB
                    comment.assign(reinterpret_cast<const char*>(&buf[pos + p]), clen);
                }
                p += clen;
                size_t eq = comment.find('=');
                if (eq != std::string::npos) {
                    std::string key = comment.substr(0, eq);
                    std::string val = comment.substr(eq + 1);
                    for (auto& c : key) {
                        c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
                    }
                    if (key == "TITLE" && m.title.empty()) {
                        m.title = val;
                    } else if (key == "ARTIST" && m.artist == "未知艺术家") {
                        m.artist = val;
                    } else if (key == "ALBUM" && m.album == "未知专辑") {
                        m.album = val;
                    } else if (key == "DATE" && m.year.empty()) {
                        m.year = val;
                    }
                }
            }
        }
        pos += len;
    }
    return m;
}

// ===== MP3：ID3v2 文本帧 + MPEG 帧头（采样率/声道/近似时长） =====
AudioMetadata parseMp3(const std::vector<unsigned char>& buf) {
    AudioMetadata m;
    m.title = "";
    m.artist = "未知艺术家";
    m.album = "未知专辑";
    m.year = "";
    m.durationMs = 0;
    m.sampleRate = 44100;
    m.channels = 2;
    m.bitDepth = 0;
    m.codec = "mp3";

    size_t pos = 0;
    if (buf.size() >= 10 && buf[0] == 'I' && buf[1] == 'D' && buf[2] == '3') {
        unsigned int tagSize = static_cast<unsigned int>(syncsafeToInt(&buf[6]));
        unsigned char ver = buf[3];
        unsigned int p = 10;
        while (p + 10 <= buf.size() && p < 10 + tagSize) {
            if (!(buf[p] == 'T' && buf[p + 1] >= 'A' && buf[p + 1] <= 'Z')) {
                break;
            }
            unsigned int fsize;
            if (ver == 4) {
                fsize = static_cast<unsigned int>(syncsafeToInt(&buf[p + 4]));
            } else {
                fsize = (static_cast<unsigned int>(buf[p + 4]) << 24) |
                        (static_cast<unsigned int>(buf[p + 5]) << 16) |
                        (static_cast<unsigned int>(buf[p + 6]) << 8) |
                        static_cast<unsigned int>(buf[p + 7]);
            }
            size_t bodyStart = static_cast<size_t>(p) + 10;
            // P0-3：用 uint64 做边界判断，杜绝 bodyStart+fsize 回绕
            if (fsize < 1 || static_cast<uint64_t>(bodyStart) + fsize > buf.size()) {
                break;
            }
            unsigned char enc = buf[bodyStart];
            unsigned int txtOff = static_cast<unsigned int>(bodyStart) + 1;
            unsigned int txtLen = fsize - 1;
            std::string text;
            if (enc == 1 || enc == 2) { // 0x01=UTF-16 带 BOM，0x02=UTF-16BE 无 BOM
                // P1-6：记录字节序并做 UTF-16 → UTF-8 转换，中文不再乱码。
                // enc==0x02 按 ID3v2.4 规范固定为大端且不带 BOM，默认值必须是 BE，
                // 否则整段中文会按 LE 解出乱码。
                bool isBE = (enc == 2);
                unsigned int s = txtOff;
                if (txtLen >= 2 && buf[s] == 0xFF && buf[s + 1] == 0xFE) {
                    s += 2;
                    isBE = false;
                } else if (txtLen >= 2 && buf[s] == 0xFE && buf[s + 1] == 0xFF) {
                    s += 2;
                    isBE = true;
                }
                for (unsigned int i = s; i + 1 < txtOff + txtLen; i += 2) {
                    uint16_t u = isBE
                        ? static_cast<uint16_t>((static_cast<uint16_t>(buf[i]) << 8) | buf[i + 1])
                        : static_cast<uint16_t>((static_cast<uint16_t>(buf[i + 1]) << 8) | buf[i]);
                    if (u == 0) {
                        break;
                    }
                    if (u < 0x80) {
                        text.push_back(static_cast<char>(u));
                    } else if (u < 0x800) {
                        text.push_back(static_cast<char>(0xC0 | (u >> 6)));
                        text.push_back(static_cast<char>(0x80 | (u & 0x3F)));
                    } else {
                        text.push_back(static_cast<char>(0xE0 | (u >> 12)));
                        text.push_back(static_cast<char>(0x80 | ((u >> 6) & 0x3F)));
                        text.push_back(static_cast<char>(0x80 | (u & 0x3F)));
                    }
                }
            } else { // Latin1 / UTF-8
                unsigned int s = txtOff;
                if (enc == 3 && txtLen >= 3 && buf[s] == 0xEF && buf[s + 1] == 0xBB && buf[s + 2] == 0xBF) {
                    s += 3;
                }
                // P2-3：钳制到缓冲区与帧边界，杜绝畸形帧尺寸导致的越界读取（UB）
                const size_t bufSize = buf.size();
                const size_t sClamped = (s < bufSize) ? s : bufSize;
                const size_t frameEnd = (static_cast<size_t>(txtOff) + static_cast<size_t>(txtLen) < bufSize)
                    ? (static_cast<size_t>(txtOff) + static_cast<size_t>(txtLen)) : bufSize;
                const size_t take = (frameEnd > sClamped) ? (frameEnd - sClamped) : 0;
                // P2-1：take==0 且 sClamped==bufSize 时，&buf[sClamped] 是过尾索引（vector::operator[] UB）
                if (take > 0) {
                    text.assign(reinterpret_cast<const char*>(&buf[sClamped]), take);
                }
            }
            std::string key(reinterpret_cast<const char*>(&buf[p]), 4);
            if (key == "TIT2" && m.title.empty()) {
                m.title = trimCopy(text);
            } else if (key == "TPE1" && m.artist == "未知艺术家") {
                m.artist = trimCopy(text);
            } else if (key == "TALB" && m.album == "未知专辑") {
                m.album = trimCopy(text);
            } else if ((key == "TYER" || key == "TDRC") && m.year.empty()) {
                m.year = trimCopy(text);
            }
            p = static_cast<unsigned int>(bodyStart) + fsize;
        }
        pos = 10 + tagSize;
    }

    // 扫描首个 MPEG 帧头，取码率/采样率估算时长
    // P2-5：帧同步二次校验 —— 命中首个 0xFF Ex 后按计算出的 frameLen 跳到下一帧头，
    // 校验第二帧同为合法帧头且版本/层/采样率索引一致；连续 2 帧一致才采信首帧参数，
    // 避免 ID3 后随机字节伪同步。外层循环 i 单调递增、天然有上界，无死循环风险。
    size_t i = pos;
    int ver = 0, layer = 0, brIdx = 0, srIdx = 0, chanMode = 0, frameLen = 0;
    for (; i + 4 < buf.size(); i++) {
        if (!parseMpegFrameHeader(buf, i, ver, layer, brIdx, srIdx, chanMode, frameLen)) {
            continue;
        }
        const size_t next = i + static_cast<size_t>(frameLen);
        if (next + 4 <= buf.size()) {
            int ver2 = 0, layer2 = 0, brIdx2 = 0, srIdx2 = 0, chanMode2 = 0, frameLen2 = 0;
            if (parseMpegFrameHeader(buf, next, ver2, layer2, brIdx2, srIdx2, chanMode2, frameLen2) &&
                ver2 == ver && layer2 == layer && srIdx2 == srIdx) {
                break; // 连续 2 帧一致：采信首帧参数
            }
        }
    }
    if (i + 4 < buf.size()) {
        const int verIdx = (ver == 3) ? 0 : (ver == 2 ? 1 : 2);
        const int sr = kSrTable[verIdx][srIdx];
        const int layerIdx = 3 - layer; // P1-3：layer 3(I)→0, 2(II)→1, 1(III)→2
        const int bitrate = kBrTable[verIdx][layerIdx][brIdx];

        // P2-10：VBR 文件带 Xing/Info 头，给出总帧数，可精确估算时长（优于 CBR 近似）。
        // Xing/Info 头只在 Layer III 中定义，且其偏移取决于 side information 长度；
        // layerBits 语义为 3=Layer I / 2=Layer II / 1=Layer III，因此只在 layer==1 时探测。
        if (layer == 1) {
            // MPEG1：单声道 17 字节、其余 32 字节；MPEG2/2.5：单声道 9 字节、其余 17 字节
            int sideInfo = (ver == 3) ? ((chanMode == 3) ? 17 : 32) : ((chanMode == 3) ? 9 : 17);
            size_t xingOff = i + 4 + static_cast<size_t>(sideInfo);
            if (xingOff + 12 <= buf.size() &&
                (tagEq(&buf[xingOff], "Xing") || tagEq(&buf[xingOff], "Info"))) {
                uint32_t flags = (static_cast<uint32_t>(buf[xingOff + 4]) << 24) |
                                 (static_cast<uint32_t>(buf[xingOff + 5]) << 16) |
                                 (static_cast<uint32_t>(buf[xingOff + 6]) << 8) |
                                 static_cast<uint32_t>(buf[xingOff + 7]);
                if (flags & 0x00000001u) { // frames 字段存在
                    uint32_t frames = (static_cast<uint32_t>(buf[xingOff + 8]) << 24) |
                                      (static_cast<uint32_t>(buf[xingOff + 9]) << 16) |
                                      (static_cast<uint32_t>(buf[xingOff + 10]) << 8) |
                                      static_cast<uint32_t>(buf[xingOff + 11]);
                    int spf = spfForFrame(ver, layer); // P2-3：显式 Layer 区分（此处恒为 Layer III）
                    if (frames > 0 && sr > 0) {
                        m.durationMs = static_cast<int>(
                            static_cast<uint64_t>(frames) * static_cast<uint64_t>(spf) * 1000ull /
                            static_cast<uint64_t>(sr));
                    }
                }
            }
        }

        // CBR 兜底：VBR 头缺失时用音频字节数估算
        // P2-4：先扣除文件尾部 ID3v1（128B，以 "TAG" 开头）或 APE（footer 以 "APETAGEX" 开头）标签，
        // 避免把标签字节计入音频时长导致时长偏大。
        if (m.durationMs <= 0 && bitrate > 0) {
            long long audioBytes = static_cast<long long>(buf.size()) - static_cast<long long>(pos);
            if (audioBytes > 0) {
                const size_t fileSize = buf.size();
                if (fileSize >= 128 && buf[fileSize - 128] == 'T' && buf[fileSize - 127] == 'A' &&
                    buf[fileSize - 126] == 'G') {
                    audioBytes -= 128; // ID3v1 固定 128 字节
                } else if (fileSize >= 32 && buf[fileSize - 32] == 'A' && buf[fileSize - 31] == 'P' &&
                           buf[fileSize - 30] == 'E' && buf[fileSize - 29] == 'T' &&
                           buf[fileSize - 28] == 'A' && buf[fileSize - 27] == 'G' &&
                           buf[fileSize - 26] == 'E' && buf[fileSize - 25] == 'X') {
                    // APE footer 在文件最后 32 字节，其 size 字段（LE，offset 8）为 header+items
                    // 大小（不含 footer 本身），故整个 tag 大小为 apeSize + 32
                    const uint32_t apeSize =
                        static_cast<uint32_t>(buf[fileSize - 32 + 8]) |
                        (static_cast<uint32_t>(buf[fileSize - 32 + 9]) << 8) |
                        (static_cast<uint32_t>(buf[fileSize - 32 + 10]) << 16) |
                        (static_cast<uint32_t>(buf[fileSize - 32 + 11]) << 24);
                    const uint64_t totalTag = static_cast<uint64_t>(apeSize) + 32u;
                    if (totalTag <= static_cast<uint64_t>(audioBytes)) {
                        audioBytes -= static_cast<long long>(totalTag);
                    }
                }
            }
            if (audioBytes > 0) {
                m.durationMs = static_cast<int>(audioBytes * 8.0 / (bitrate * 1000.0) * 1000.0);
            }
        }
        m.sampleRate = sr;
        m.channels = (chanMode == 3) ? 1 : 2;
    }
    return m;
}

// ===== MP4/M4A：递归遍历 atom，取 mvhd 时长 + ilst 文本 =====
// P1-5：增加 depth 上限，防止畸形文件（数千层嵌套 moov）栈溢出
// P2-9：支持 64-bit largesize（size 字段 == 1 时，后续 8 字节为真实长度）
void walkAtoms(const std::vector<unsigned char>& buf, size_t start, size_t end,
               uint32_t& mvhdDur, uint32_t& mvhdTs, AudioMetadata& m, bool& outAlac, int depth = 0) {
    if (depth > 16) {
        return;
    }
    size_t pos = start;
    while (pos + 8 <= end && pos + 8 <= buf.size()) {
        uint64_t size64 = (static_cast<uint64_t>(buf[pos]) << 24) |
                          (static_cast<uint64_t>(buf[pos + 1]) << 16) |
                          (static_cast<uint64_t>(buf[pos + 2]) << 8) |
                          static_cast<uint64_t>(buf[pos + 3]);
        size_t headerLen = 8;
        if (size64 == 1) { // 64-bit largesize：真实长度在随后的 8 字节
            if (pos + 16 > end || pos + 16 > buf.size()) {
                break;
            }
            size64 = (static_cast<uint64_t>(buf[pos + 8]) << 56) |
                     (static_cast<uint64_t>(buf[pos + 9]) << 48) |
                     (static_cast<uint64_t>(buf[pos + 10]) << 40) |
                     (static_cast<uint64_t>(buf[pos + 11]) << 32) |
                     (static_cast<uint64_t>(buf[pos + 12]) << 24) |
                     (static_cast<uint64_t>(buf[pos + 13]) << 16) |
                     (static_cast<uint64_t>(buf[pos + 14]) << 8) |
                     static_cast<uint64_t>(buf[pos + 15]);
            headerLen = 16;
        }
        if (size64 == 0) {
            // P2-2：ISO/IEC 14496-12 规定 size==0 表示「延伸至文件尾」。
            // 若不处理，size=0 的 moov/mdat 之后的所有 metadata（mvhd/ilst）会被跳过。
            // 循环入口已保证 pos + 8 <= buf.size()，此处减法不会下溢。
            size64 = static_cast<uint64_t>(buf.size() - pos);
        }
        if (size64 < static_cast<uint64_t>(headerLen)) {
            break;
        }
        // P0-4：atom 越出文件尾则视为损坏，避免后续按 size 场读数越界。
        // 必须用减法比较而不是 pos + size64 > buf.size()：largesize 可取到接近 UINT64_MAX，
        // 相加会按 2^64 回绕得到极小值从而绕过检查，pos 原地不动造成死循环 / ANR。
        // 循环入口已保证 pos + 8 <= buf.size()，故 buf.size() - pos 恒不下溢。
        if (size64 > static_cast<uint64_t>(buf.size() - pos)) {
            break;
        }
        const unsigned char* t = &buf[pos + 4];
        if (tagEq(t, "alac")) {
            outAlac = true;
        }
        if (tagEq(t, "mvhd")) {
            // P0-4：mvhd 补全边界检查，按 version 计算所需字节数
            size_t p = pos + headerLen;
            if (p >= buf.size()) {
                break;
            }
            size_t need = (buf[p] == 0) ? 20u : 32u; // v0 需 20 字节，v1 需 32 字节
            if (p + need > buf.size()) {
                break;
            }
            unsigned char mv = buf[p];
            if (mv == 0) {
                mvhdTs = (static_cast<uint32_t>(buf[p + 12]) << 24) |
                         (static_cast<uint32_t>(buf[p + 13]) << 16) |
                         (static_cast<uint32_t>(buf[p + 14]) << 8) |
                         static_cast<uint32_t>(buf[p + 15]);
                mvhdDur = (static_cast<uint32_t>(buf[p + 16]) << 24) |
                          (static_cast<uint32_t>(buf[p + 17]) << 16) |
                          (static_cast<uint32_t>(buf[p + 18]) << 8) |
                          static_cast<uint32_t>(buf[p + 19]);
            } else {
                mvhdTs = (static_cast<uint32_t>(buf[p + 20]) << 24) |
                         (static_cast<uint32_t>(buf[p + 21]) << 16) |
                         (static_cast<uint32_t>(buf[p + 22]) << 8) |
                         static_cast<uint32_t>(buf[p + 23]);
                // mvhd v1 的 duration 是 64 位（p+24..p+31），只读前 4 字节拿到的是高位，
                // 实际时长几乎总落在低 32 位，会导致时长恒为 0。这里读满 64 位再做饱和收敛。
                uint64_t dur64 = (static_cast<uint64_t>(buf[p + 24]) << 56) |
                                 (static_cast<uint64_t>(buf[p + 25]) << 48) |
                                 (static_cast<uint64_t>(buf[p + 26]) << 40) |
                                 (static_cast<uint64_t>(buf[p + 27]) << 32) |
                                 (static_cast<uint64_t>(buf[p + 28]) << 24) |
                                 (static_cast<uint64_t>(buf[p + 29]) << 16) |
                                 (static_cast<uint64_t>(buf[p + 30]) << 8) |
                                 static_cast<uint64_t>(buf[p + 31]);
                mvhdDur = (dur64 > 0xFFFFFFFFull) ? 0xFFFFFFFFu : static_cast<uint32_t>(dur64);
            }
        } else if (tagEq(t, "ilst")) {
            size_t child = pos + headerLen;
            size_t childEnd = static_cast<size_t>(pos + size64);
            while (child + 8 <= childEnd && child + 8 <= buf.size()) {
                uint32_t cs = (static_cast<uint32_t>(buf[child]) << 24) |
                              (static_cast<uint32_t>(buf[child + 1]) << 16) |
                              (static_cast<uint32_t>(buf[child + 2]) << 8) |
                              static_cast<uint32_t>(buf[child + 3]);
                if (cs < 8) {
                    break;
                }
                const unsigned char* ct = &buf[child + 4];
                size_t dpos = child + 8;
                size_t dEnd = child + cs;
                while (dpos + 8 <= dEnd && dpos + 8 <= buf.size()) {
                    uint32_t ds = (static_cast<uint32_t>(buf[dpos]) << 24) |
                                  (static_cast<uint32_t>(buf[dpos + 1]) << 16) |
                                  (static_cast<uint32_t>(buf[dpos + 2]) << 8) |
                                  static_cast<uint32_t>(buf[dpos + 3]);
                    // P0-5：data 原子至少 16 字节（size+type+ver/flags+typecode），否则下溢
                    if (ds < 16) {
                        break;
                    }
                    if (tagEq(&buf[dpos + 4], "data")) {
                        size_t vp = dpos + 16; // skip size+type+version/flags+typecode+locale
                        size_t vlen = ds - 16;
                        if (vp + vlen > buf.size()) {
                            break;
                        }
                        std::string val;
                        // P2-1：vlen==0 且 vp==buf.size() 时，&buf[vp] 是过尾索引（vector::operator[] UB）
                        if (vlen > 0) {
                            val.assign(reinterpret_cast<const char*>(&buf[vp]), vlen);
                        }
                        val = trimCopy(val);
                        // P1-2：用真实 4 字节版权符原子名（0xA9 + 字母），原 UTF-8 双字节写法永不匹配
                        if (tagEq(ct, kNam) && m.title.empty()) {
                            m.title = val;
                        } else if ((tagEq(ct, kART) || tagEq(ct, kaART)) && m.artist == "未知艺术家") {
                            m.artist = val;
                        } else if (tagEq(ct, kAlb) && m.album == "未知专辑") {
                            m.album = val;
                        } else if (tagEq(ct, kDay) && m.year.empty()) {
                            m.year = val;
                        }
                        break;
                    }
                    dpos += ds;
                }
                child += cs;
            }
        } else if (tagEq(t, "meta")) {
            // meta 是 FullBox：atom 头(headerLen) + 4 字节 version/flags，子 box 从其后开始
            walkAtoms(buf, pos + headerLen + 4, static_cast<size_t>(pos + size64), mvhdDur, mvhdTs, m, outAlac, depth + 1);
        } else if (tagEq(t, "moov") || tagEq(t, "trak") || tagEq(t, "mdia") ||
                   tagEq(t, "minf") || tagEq(t, "stbl") || tagEq(t, "udta")) {
            walkAtoms(buf, pos + headerLen, static_cast<size_t>(pos + size64), mvhdDur, mvhdTs, m, outAlac, depth + 1);
        }
        pos += static_cast<size_t>(size64);
    }
}

AudioMetadata parseMp4(const std::vector<unsigned char>& buf) {
    AudioMetadata m;
    m.title = "";
    m.artist = "未知艺术家";
    m.album = "未知专辑";
    m.year = "";
    m.durationMs = 0;
    m.sampleRate = 44100;
    m.channels = 2;
    m.bitDepth = 0;
    m.codec = "m4a";
    uint32_t dur = 0;
    uint32_t ts = 0;
    bool foundAlac = false;
    walkAtoms(buf, 0, buf.size(), dur, ts, m, foundAlac);
    if (ts > 0 && dur > 0) {
        m.durationMs = static_cast<int>(static_cast<uint64_t>(dur) * 1000 / ts);
    }
    // ALAC 为无损编码；其余 M4A 多为 AAC 损耗编码（bitDepth 置 0 表示不适用）
    if (foundAlac) {
        m.codec = "alac";
    }
    return m;
}

AudioMetadata parseWav(const std::vector<unsigned char>& buf) {
    AudioMetadata m;
    m.title = "";
    m.artist = "未知艺术家";
    m.album = "未知专辑";
    m.year = "";
    m.durationMs = 0;
    m.sampleRate = 44100;
    m.channels = 2;
    m.bitDepth = 0;
    m.codec = "wav";
    // 校验 RIFF....WAVE
    if (buf.size() < 12 ||
        !(buf[0] == 'R' && buf[1] == 'I' && buf[2] == 'F' && buf[3] == 'F') ||
        !(buf[8] == 'W' && buf[9] == 'A' && buf[10] == 'V' && buf[11] == 'E')) {
        return m;
    }
    size_t pos = 12;
    while (pos + 8 <= buf.size()) {
        // chunk: 4 字节 ID + 4 字节小端 size + data（按字对齐，奇数 size 后补 1 字节）
        uint32_t cs = (static_cast<uint32_t>(buf[pos])) |
                      (static_cast<uint32_t>(buf[pos + 1]) << 8) |
                      (static_cast<uint32_t>(buf[pos + 2]) << 16) |
                      (static_cast<uint32_t>(buf[pos + 3]) << 24);
        uint32_t sz = (static_cast<uint32_t>(buf[pos + 4])) |
                      (static_cast<uint32_t>(buf[pos + 5]) << 8) |
                      (static_cast<uint32_t>(buf[pos + 6]) << 16) |
                      (static_cast<uint32_t>(buf[pos + 7]) << 24);
        // 防回绕：size 与偏移相加可能溢出，用减法比较代替 pos+8+sz > buf.size()
        if (cs < 4 || sz == 0 || static_cast<uint64_t>(pos) + 8 + sz > buf.size()) {
            break;
        }
        const unsigned char* t = &buf[pos];
        if (t[0] == 'f' && t[1] == 'm' && t[2] == 't' && t[3] == ' ') {
            size_t p = pos + 8;
            if (p + 16 <= buf.size()) {
                uint16_t ch = static_cast<uint16_t>(buf[p + 2] | (buf[p + 3] << 8));
                uint32_t sr = (static_cast<uint32_t>(buf[p + 4])) |
                              (static_cast<uint32_t>(buf[p + 5]) << 8) |
                              (static_cast<uint32_t>(buf[p + 6]) << 16) |
                              (static_cast<uint32_t>(buf[p + 7]) << 24);
                uint16_t bits = static_cast<uint16_t>(buf[p + 14] | (buf[p + 15] << 8));
                if (sr > 0 && ch > 0) {
                    m.sampleRate = static_cast<int>(sr);
                    m.channels = static_cast<int>(ch);
                    m.bitDepth = static_cast<int>(bits);
                }
            }
            break; // fmt 通常仅一个，取首个即可
        }
        pos += 8 + static_cast<size_t>(sz);
        if (sz & 1) {
            pos += 1; // WAV chunk 按字对齐，奇数 size 后补 1 字节
        }
    }
    return m;
}

} // namespace

AudioMetadata parseAudioMetadata(const std::string& filePath) {
    AudioMetadata metadata;
    metadata.title = "";
    metadata.artist = "未知艺术家";
    metadata.album = "未知专辑";
    metadata.year = "";
    metadata.durationMs = 0;
    metadata.sampleRate = 44100;
    metadata.channels = 2;
    metadata.bitDepth = 0;
    metadata.codec = "";

    // 默认标题取文件名（无扩展名）
    size_t lastSlash = filePath.find_last_of('/');
    size_t lastDot = filePath.find_last_of('.');
    if (lastSlash != std::string::npos && lastDot != std::string::npos && lastDot > lastSlash) {
        metadata.title = filePath.substr(lastSlash + 1, lastDot - lastSlash - 1);
    } else if (lastSlash != std::string::npos) {
        metadata.title = filePath.substr(lastSlash + 1);
    } else {
        metadata.title = filePath;
    }

    // 预判文件格式，按格式限制读取大小（NFR 资源占用）：
    // FLAC/MP3 的元数据块在文件头部（2MB 覆盖 >99.9% 的文件），无需将整首歌曲读入内存。
    // MP4/M4A 的 moov atom 可能位于文件末尾，必须全量读取（maxRead=0 表示无限制）。
    std::string lower = filePath;
    for (auto& c : lower) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    size_t maxRead = 0;
    if (endsWith(lower, ".flac") || endsWith(lower, ".mp3") || endsWith(lower, ".wav") ||
        endsWith(lower, ".wave")) {
        maxRead = 2u * 1024u * 1024u; // 2MB — 头部元数据/RIFF fmt 块足够覆盖
    }

    std::vector<unsigned char> buf;
    if (!readFile(filePath, buf, maxRead)) {
        return metadata;
    }

    AudioMetadata parsed;
    if (endsWith(lower, ".flac")) {
        parsed = parseFlac(buf);
    } else if (endsWith(lower, ".mp3")) {
        parsed = parseMp3(buf);
    } else if (endsWith(lower, ".m4a") || endsWith(lower, ".mp4") ||
               endsWith(lower, ".aac") || endsWith(lower, ".m4b")) {
        parsed = parseMp4(buf);
    } else if (endsWith(lower, ".wav") || endsWith(lower, ".wave")) {
        parsed = parseWav(buf);
    } else {
        return metadata; // 未知格式：保留文件名标题
    }

    // 合并：仅用解析出的有效字段覆盖默认值
    if (!parsed.title.empty()) {
        metadata.title = parsed.title;
    }
    if (parsed.artist != "未知艺术家") {
        metadata.artist = parsed.artist;
    }
    if (parsed.album != "未知专辑") {
        metadata.album = parsed.album;
    }
    if (!parsed.year.empty()) {
        metadata.year = parsed.year;
    }
    if (parsed.durationMs > 0) {
        metadata.durationMs = parsed.durationMs;
    }
    if (parsed.sampleRate > 0) {
        metadata.sampleRate = parsed.sampleRate;
    }
    if (parsed.channels > 0) {
        metadata.channels = parsed.channels;
    }
    if (parsed.bitDepth > 0) {
        metadata.bitDepth = parsed.bitDepth;
    }
    if (!parsed.codec.empty()) {
        metadata.codec = parsed.codec;
    }
    return metadata;
}
