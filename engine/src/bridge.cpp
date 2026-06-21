#include <cstdint>
#include <thread>
#include <atomic>
#include <string>
#include <fstream>
#include <ctime>
#include <mutex>
#include <cstdlib>
#include <map>
#include <vector>
#include <deque>
#include <sstream>

struct Ohlc {
    int open = 0, high = 0, low = 0, close = 0;
    long volume = 0;
    long time = 0; // unix timestamp menit
};

struct Trade {
    long time;
    int price;
    int lot;
};

std::atomic<bool> running(false);
std::map<std::string, Ohlc> last_ticks; // data hari ini
std::map<std::string, std::deque<Ohlc>> candles_1m; // history 1 menit
std::deque<Trade> running_trades; // 50 trade terakhir
std::string all_data_json = "{}";
std::mutex tick_mutex;
const char* CACHE_DIR = "/data/data/com.contoh.appbei/";
const int MAX_CANDLES = 390; // 6.5 jam trading
const int MAX_TRADES = 50;

const std::vector<std::string> WATCHLIST = {
    "IHSG", "BBCA", "BBRI", "BMRI", "TLKM", "ASII", "GOTO", "UNVR"
};

bool isMarketOpen() {
    time_t now = time(0);
    tm *ltm = localtime(&now);
    int hour = ltm->tm_hour, minute = ltm->tm_min, wday = ltm->tm_wday;
    if (wday == 0 || wday == 6) return false;
    bool s1 = (hour > 9 || (hour == 9 && minute >= 0)) && (hour < 11 || (hour == 11 && minute <= 30));
    bool s2 = false;
    if (wday >= 1 && wday <= 4) s2 = (hour == 13 && minute >= 30) || (hour == 14);
    else if (wday == 5) s2 = (hour == 14);
    return s1 || s2;
}

long getCurrentMinute() {
    return time(0) / 60 * 60; // buang detik
}

void saveCandleToFile(const std::string& code, const Ohlc& c) {
    std::lock_guard<std::mutex> lock(tick_mutex);
    std::string path = std::string(CACHE_DIR) + code + "_1m.csv";
    std::ofstream file(path, std::ios::app);
    if (file.is_open()) {
        file << c.time << "," << c.open << "," << c.high << "," << c.low << "," << c.close << "," << c.volume << "\n";
        file.close();
    }
}

void loadCandlesFromFile(const std::string& code) {
    std::lock_guard<std::mutex> lock(tick_mutex);
    std::string path = std::string(CACHE_DIR) + code + "_1m.csv";
    std::ifstream file(path);
    std::string line;
    candles_1m[code].clear();
    while (std::getline(file, line)) {
        Ohlc c;
        sscanf(line.c_str(), "%ld,%d,%d,%d,%d,%ld", &c.time, &c.open, &c.high, &c.low, &c.close, &c.volume);
        candles_1m[code].push_back(c);
    }
    file.close();
}

void updateJson() {
    std::stringstream ss;
    ss << "{";
    ss << "\"market_open\":" << (isMarketOpen()? "true" : "false") << ",";

    // 1. OHLC hari ini
    ss << "\"stocks\":{";
    bool first = true;
    for (auto const& [code, ohlc] : last_ticks) {
        if (!first) ss << ",";
        ss << "\"" << code << "\":{";
        ss << "\"o\":" << ohlc.open << ",\"h\":" << ohlc.high;
        ss << ",\"l\":" << ohlc.low << ",\"c\":" << ohlc.close;
        ss << ",\"v\":" << ohlc.volume << "}";
        first = false;
    }
    ss << "},";

    // 2. Running trade
    ss << "\"trades\":[";
    for (size_t i = 0; i < running_trades.size(); ++i) {
        if (i > 0) ss << ",";
        ss << "{\"t\":" << running_trades[i].time;
        ss << ",\"p\":" << running_trades[i].price;
        ss << ",\"l\":" << running_trades[i].lot << "}";
    }
    ss << "]}";
    all_data_json = ss.str();
}

void feed_loop() {
    for (const auto& code : WATCHLIST) {
        loadCandlesFromFile(code);
        if (!candles_1m[code].empty()) {
            last_ticks[code] = candles_1m[code].back();
        } else {
            last_ticks[code] = {1000, 1000, 1000, 1000, 0, getCurrentMinute()};
        }
    }
    updateJson();

    long last_minute = getCurrentMinute();

    while (running) {
        if (isMarketOpen()) {
            long current_minute = getCurrentMinute();
            bool new_minute = current_minute!= last_minute;

            for (auto& [code, ohlc] : last_ticks) {
                int newPrice = ohlc.close + rand() % 10 - 4; // TODO: ganti data BEI
                if (newPrice < 1) newPrice = 1;
                int newLot = rand() % 50 + 1;

                // Running trade
                running_trades.push_front({time(0), newPrice, newLot});
                if (running_trades.size() > MAX_TRADES) running_trades.pop_back();

                if (new_minute) {
                    // Simpan candle menit sebelumnya
                    ohlc.time = last_minute;
                    candles_1m[code].push_back(ohlc);
                    if (candles_1m[code].size() > MAX_CANDLES) candles_1m[code].pop_front();
                    saveCandleToFile(code, ohlc);

                    // Buka candle baru
                    ohlc.open = newPrice;
                    ohlc.high = newPrice;
                    ohlc.low = newPrice;
                    ohlc.volume = 0;
                }

                if (newPrice > ohlc.high) ohlc.high = newPrice;
                if (newPrice < ohlc.low) ohlc.low = newPrice;
                ohlc.close = newPrice;
                ohlc.volume += newLot * 100; // 1 lot = 100 lembar
            }
            last_minute = current_minute;
        }
        updateJson();
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
}

extern "C" {
__attribute__((visibility("default"))) __attribute__((used))
void start_feed() {
    if (!running) {
        running = true;
        std::thread(feed_loop).detach();
    }
}

__attribute__((visibility("default"))) __attribute__((used))
const char* get_all_data() {
    return all_data_json.c_str();
}

// Buat ambil candle history 1 saham
__attribute__((visibility("default"))) __attribute__((used))
const char* get_candles(const char* code) {
    static std::string json;
    std::stringstream ss;
    ss << "[";
    if (candles_1m.count(code)) {
        bool first = true;
        for (const auto& c : candles_1m[code]) {
            if (!first) ss << ",";
            ss << "{\"t\":" << c.time << ",\"o\":" << c.open;
            ss << ",\"h\":" << c.high << ",\"l\":" << c.low;
            ss << ",\"c\":" << c.close << ",\"v\":" << c.volume << "}";
            first = false;
        }
    }
    ss << "]";
    json = ss.str();
    return json.c_str();
}
}