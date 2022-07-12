
#ifndef __PINTOOL_REGION_HPP_
#define __PINTOOL_REGION_HPP_

#include <map>
#include <string>
#include <fstream>

struct AccessStats {

  int32_t read_count;
  int32_t write_count;

};

struct Region {

  // Number of bytes counted as a single access
  static constexpr int MEMORY_ACCESS_GRANULARITY = 4;

  typedef std::map<uint64_t, AccessStats>::iterator iter_t;
  std::map<uint64_t, AccessStats> _counts;
  std::string _region_name;
  int32_t _count;
  int32_t _cacheline_size;

  Region(std::string region_name, int32_t cacheline_size):
    _region_name(region_name),
    _count(0),
    _cacheline_size(cacheline_size)
  {}

  void write(uintptr_t addr, int32_t size);
  void read(uintptr_t addr, int32_t size);
  void print(std::ofstream &);
  void reset();

  int32_t count() const;

  uintptr_t align_address(uintptr_t addr);

};

struct Regions {

  std::ofstream log_file;
  std::map<std::string, Region*> _regions;
  std::string _file_name;

  typedef std::map<std::string, Region*>::iterator iter_t;

  ~Regions();

  void filename(const std::string& filename);
  Region* start_region(std::string name, int cacheline_size);
  void end_region(Region*);
  void open(const std::string& region);
  void close();

};

struct HostEvent
{
  std::string region_name;
  int counter;

  HostEvent():
    region_name(""),
    counter(-1)
  {}

  HostEvent(std::string region_name, int counter):
    region_name(region_name),
    counter(counter)
  {}

  bool empty() const;

  void print(std::ofstream &, const std::string &) const;

};

struct HostRegionChange
{
  HostEvent before, after;

  HostRegionChange(const HostEvent & pred):
    before(pred)
  {}

  HostRegionChange()
  {}

  void print(std::ofstream &, const std::string &) const;

};

#endif

