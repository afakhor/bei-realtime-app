#include <thread>
#include <atomic>
#include <string>
#include <fstream>
#include <ctime>
#include <mutex>

std::atomic<bool> running(false);
std::string last_tick = "0";
std::mutex tick_mutex;
const char* CACHE_FILE = "/data/data/com.example.bei_realtime_app/last_tick.txt"; // path Android

bool isMarketOpen() {
    time_t now = time(0);
    tm *ltm = localtime(&now);
    int hour = ltm->tm_hour;
    int wday = ltm->tm_wday; // 0 = Minggu, 6 = Sabtu
    
    if (wday == 0 || wday == 6) return false;
    // Sesi 1: 09:00-11:30, Sesi 2: 13:30-15:49
    if ((hour >= 9 && hour < 12) || (hour == 13 && ltm->tm_min >= 30) || (hour > 13 && hour < 16)) {
        return true;
    }
    return false;
}

void saveToCache(const std::string& data) {
    std::lock_guard<std::mutex> lock(tick_mutex);
    std::ofstream file(CACHE_FILE);
    if (file.is_open()) {
        file << data;
        file.close();
    }
}

std::string loadFromCache() {
    std::lock_guard<std::mutex> lock(tick_mutex);
    std::ifstream file(CACHE_FILE);
    std::string data = "0";
    if (file.is_open()) {
        std::getline(file, data);
        file.close();
    }
    return data;
}

void feed_loop() {
    int price = 7000;
    while (running) {
        if (isMarketOpen()) {
            // TODO: ambil data BEI asli di sini
            price += rand() % 10 - 4; // ganti sama data real
            last_tick = std::to_string(price);
            saveToCache(last_tick); // simpan tiap update
        } else {
            // market tutup, pake cache aja
            last_tick = loadFromCache();
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
}

extern "C" {
    void start_feed() {
        if (!running) {
            running = true;
            // load cache dulu biar langsung ada data pas buka app
            last_tick = loadFromCache();
            std::thread(feed_loop).detach();
        }
    }
    
    const char* get_last_tick() {
        return last_tick.c_str();
    }
    
    int native_add(int a, int b) {
        return a + b;
    }
}