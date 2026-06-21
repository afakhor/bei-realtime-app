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

struct Ohlc {
    int open = 0;
    int high = 0;
    int low = 0;
    int close = 0;
};

std::atomic<bool> running(false);
std::map<std::string, Ohlc> last_ticks; // BBCA -> Ohlc
std::string all_ticks_json = "{}";
std::mutex tick_mutex;
const char* CACHE_DIR = "/data/data/com.contoh.appbei/";

const std::vector<std::string> WATCHLIST = {
    "IHSG", "LQ45", "BBCA", "BBRI", "BMRI", "TLKM", "ASII", "GOTO"
};

bool isMarketOpen() { /* sama kayak tadi */ }

void saveToCache(const std::string& code, const Ohlc& data) {
    std::lock_guard<std::mutex> lock(tick_mutex);
    std::string path = std::string(CACHE_DIR) + code + ".txt";
    std::ofstream file(path);
    if (file.is_open()) {
        // Format: O,H,L,C
        file << data.open << "," << data.high << "," << data.low << "," << data.close;
        file.close();
    }
}

Ohlc loadFromCache(const std::string& code) {
    std::lock_guard<std::mutex> lock(tick_mutex);
    std::string path = std::string(CACHE_DIR) + code + ".txt";
    std::ifstream file(path);
    Ohlc data;
    std::string line;
    if (file.is_open() && std::getline(file, line)) {
        sscanf(line.c_str(), "%d,%d,%d,%d", &data.open, &data.high, &data.low, &data.close);
        file.close();
    } else {
        data.open = data.high = data.low = data.close = 1000; // default
    }
    return data;
}

void updateJson() {
    std::string json = "{";
    bool first = true;
    for (auto const& [code, ohlc] : last_ticks) {
        if (!first) json += ",";
        json += "\"" + code + "\":{\"o\":" + std::to_string(ohlc.open) +
                ",\"h\":" + std::to_string(ohlc.high) +
                ",\"l\":" + std::to_string(ohlc.low) +
                ",\"c\":" + std::to_string(ohlc.close) + "}";
        first = false;
    }
    json += "}";
    all_ticks_json = json;
}

bool isNewDay() {
    static int last_day = -1;
    time_t now = time(0);
    tm *ltm = localtime(&now);
    if (ltm->tm_mday!= last_day) {
        last_day = ltm->tm_mday;
        return true;
    }
    return false;
}

void feed_loop() {
    for (const auto& code : WATCHLIST) {
        last_ticks[code] = loadFromCache(code);
    }
    updateJson();

    while (running) {
        if (isMarketOpen()) {
            bool resetOhlc = isNewDay(); // reset O,H,L,C pas ganti hari
            for (auto& [code, ohlc] : last_ticks) {
                int newPrice = ohlc.close + rand() % 10 - 4; // TODO: data BEI asli
                if (newPrice < 1) newPrice = 1;

                if (resetOhlc || ohlc.open == 0) {
                    ohlc.open = newPrice;
                    ohlc.high = newPrice;
                    ohlc.low = newPrice;
                }
                if (newPrice > ohlc.high) ohlc.high = newPrice;
                if (newPrice < ohlc.low) ohlc.low = newPrice;
                ohlc.close = newPrice;

                saveToCache(code, ohlc);
            }
        } else {
            for (auto& [code, ohlc] : last_ticks) {
                last_ticks[code] = loadFromCache(code);
            }
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
const char* get_all_ticks() {
    return all_ticks_json.c_str();
}
}