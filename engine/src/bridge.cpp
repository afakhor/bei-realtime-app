#include <cstdint>
#include <thread>
#include <atomic>
#include <string>
#include <fstream>
#include <ctime>
#include <mutex>
#include <cstdlib>

std::atomic<bool> running(false);
std::string last_tick = "0";
std::mutex tick_mutex;
// GANTI: samain sama applicationId di build.gradle.kts
const char* CACHE_FILE = "/data/data/com.contoh.appbei/last_tick.txt";

bool isMarketOpen() {
    time_t now = time(0);
    tm *ltm = localtime(&now);
    int hour = ltm->tm_hour;
    int minute = ltm->tm_min;
    int wday = ltm->tm_wday; // 0 = Minggu, 1 = Senin, ..., 6 = Sabtu
    
    if (wday == 0 || wday == 6) return false; // Weekend

    // Sesi 1: 09:00 - 11:30
    bool sesi1 = (hour > 9 || (hour == 9 && minute >= 0)) && 
                 (hour < 11 || (hour == 11 && minute <= 30));

    // Sesi 2: Senin-Kamis 13:30-14:50, Jumat 14:00-14:50
    bool sesi2 = false;
    if (wday >= 1 && wday <= 4) { // Senin-Kamis
        sesi2 = (hour == 13 && minute >= 30) || (hour == 14);
    } else if (wday == 5) { // Jumat
        sesi2 = (hour == 14);
    }

    return sesi1 || sesi2;
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
    std::string data = "7000"; // default kalau file belum ada
    if (file.is_open()) {
        std::getline(file, data);
        file.close();
    }
    return data;
}

void feed_loop() {
    int price = std::stoi(loadFromCache()); // mulai dari cache terakhir
    while (running) {
        if (isMarketOpen()) {
            // TODO: ganti ini sama koneksi BEI asli
            price += rand() % 10 - 4;
            last_tick = std::to_string(price);
            saveToCache(last_tick); // update cache cuma pas market buka
        } else {
            // market tutup, last_tick tetap nilai dari cache
            last_tick = loadFromCache();
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
}

extern "C" {

__attribute__((visibility("default"))) __attribute__((used))
int32_t native_add(int32_t a, int32_t b) {
    return a + b;
}

__attribute__((visibility("default"))) __attribute__((used))
void start_feed() {
    if (!running) {
        running = true;
        last_tick = loadFromCache(); // langsung load biar ga 0
        std::thread(feed_loop).detach();
    }
}

__attribute__((visibility("default"))) __attribute__((used))
const char* get_last_tick() {
    return last_tick.c_str();
}

}