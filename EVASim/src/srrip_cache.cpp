#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <unordered_map>
#include <vector>
#include <array>
#include <list>

namespace py = pybind11;

class SRRIPCache {
private:
    size_t cache_way;
    uint8_t rrpv_bits;
    uint8_t rrpv_insert;
    uint8_t max_rrpv;
    
    // 핵심 자료구조
    std::unordered_map<int64_t, std::pair<uint8_t, size_t>> cache_map; // key -> (rrpv, index)
    std::vector<std::vector<int64_t>> rrpv_lists; // RRPV 값별 키 목록
    std::vector<int64_t> entries; // 실제 캐시 엔트리

public:
    SRRIPCache(size_t way, uint8_t bits, uint8_t insert_val) 
        : cache_way(way)
        , rrpv_bits(bits)
        , rrpv_insert(insert_val)
        , max_rrpv((1 << bits) - 1) {
        entries.reserve(way);
        rrpv_lists.resize(max_rrpv + 1);
    }

    bool access(int64_t tag) {
        auto it = cache_map.find(tag);
        if (it != cache_map.end()) {
            // Cache hit: Reset RRPV to 0
            uint8_t old_rrpv = it->second.first;
            size_t index = it->second.second;
            
            // Remove from old RRPV list
            auto& old_list = rrpv_lists[old_rrpv];
            old_list.erase(std::remove(old_list.begin(), old_list.end(), tag), old_list.end());
            
            // Add to RRPV 0 list
            rrpv_lists[0].push_back(tag);
            it->second.first = 0;
            
            return true;
        }

        // Cache miss
        if (entries.size() < cache_way) {
            // Cache not full
            entries.push_back(tag);
            cache_map[tag] = {rrpv_insert, entries.size() - 1};
            rrpv_lists[rrpv_insert].push_back(tag);
        } else {
            bool replaced = false;
            uint8_t current_rrpv = max_rrpv;
            
            // Find victim with max RRPV
            while (!replaced && current_rrpv < max_rrpv + 1) {
                if (!rrpv_lists[current_rrpv].empty()) {
                    int64_t victim_tag = rrpv_lists[current_rrpv].back();
                    rrpv_lists[current_rrpv].pop_back();
                    
                    size_t victim_index = cache_map[victim_tag].second;
                    cache_map.erase(victim_tag);
                    
                    // Insert new entry
                    entries[victim_index] = tag;
                    cache_map[tag] = {rrpv_insert, victim_index};
                    rrpv_lists[rrpv_insert].push_back(tag);
                    replaced = true;
                } else {
                    if (current_rrpv == max_rrpv) {
                        // Increment all RRPV values
                        for (uint8_t i = 0; i < max_rrpv; i++) {
                            if (!rrpv_lists[i].empty()) {
                                for (int64_t key : rrpv_lists[i]) {
                                    cache_map[key].first = i + 1;
                                }
                                rrpv_lists[i + 1].insert(
                                    rrpv_lists[i + 1].end(),
                                    rrpv_lists[i].begin(),
                                    rrpv_lists[i].end()
                                );
                                rrpv_lists[i].clear();
                            }
                        }
                    }
                    current_rrpv--;
                }
            }
        }
        return false;
    }

    py::array_t<int64_t> get_entries() {
        std::vector<int64_t> tags;
        tags.reserve(entries.size());
        for (const auto& entry : entries) {
            tags.push_back(entry);
        }
        return py::array_t<int64_t>(
            {static_cast<int64_t>(tags.size())},
            tags.data()
        );
    }

    bool is_empty() {
        return entries.empty();
    }
};

PYBIND11_MODULE(srrip_cache, m) {
    py::class_<SRRIPCache>(m, "SRRIPCache")
        .def(py::init<size_t, uint8_t, uint8_t>())
        .def("access", &SRRIPCache::access)
        .def("get_entries", &SRRIPCache::get_entries)
        .def("is_empty", &SRRIPCache::is_empty);
}
