
#ifndef __PINTOOL_REGION_HPP_
#define __PINTOOL_REGION_HPP_

#include <map>
#include <string>
#include <fstream>

struct Region {

  std::map<uint64_t, std::pair<int, int> > _counts;
  std::string _region_name;

  typedef std::map<uint64_t, std::pair<int, int> >::iterator iter_t;

  Region(std::string region_name):
    _region_name(region_name)
  {}

  void write(uintptr_t addr, int32_t size);
  void read(uintptr_t addr, int32_t size);
  void print(std::ofstream &);
  void reset();

};

struct Regions {

  std::ofstream log_file;
  std::map<std::string, Region*> _regions;

  typedef std::map<std::string, Region*>::iterator iter_t;

  ~Regions();

  void open(const std::string& filename);
  Region* startRegion(std::string name);
  void endRegion(Region*);
  void close();

};

#endif

