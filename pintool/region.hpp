
#ifndef __PINTOOL_REGION_HPP_
#define __PINTOOL_REGION_HPP_

#include <map>
#include <string>
#include <fstream>

struct AccessStats {

  int32_t read_count;
  int32_t write_count;

  int32_t read_count_outside;
  int32_t write_count_outside;

};

struct Region {

  std::map<std::pair<uint64_t, int32_t>, AccessStats> _counts;
  std::string _region_name;
  int32_t _count;

  typedef std::map<std::pair<uint64_t, int32_t>, AccessStats>::iterator iter_t;

  Region(std::string region_name):
    _region_name(region_name),
    _count(0)
  {}

  void write(uintptr_t addr, int32_t size);
  void read(uintptr_t addr, int32_t size);
  void write_host(uintptr_t addr, int32_t size);
  void read_host(uintptr_t addr, int32_t size);
  void print(std::ofstream &);
  void reset();

};

struct Regions {

  std::ofstream log_file;
  std::map<std::string, Region*> _regions;
  std::string _file_name;

  typedef std::map<std::string, Region*>::iterator iter_t;

  ~Regions();

  void filename(const std::string& filename);
  Region* startRegion(std::string name);
  void endRegion(Region*);
  void open(const std::string& region);
  void close();

};

#endif

