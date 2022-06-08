
#include <iomanip>
#include <cstdio>

#include "region.hpp"

void Region::print(std::ofstream & of)
{
  of << "#region " << _region_name << " " << _counts.size() << '\n';
  for(iter_t it = _counts.begin(); it != _counts.end(); ++it) {
    of << std::hex << (*it).first.first << std::dec << " " << (*it).first.second << " " << (*it).second.first << " " << (*it).second.second << '\n';
  }
}

void Region::read(uintptr_t addr, int32_t size)
{

  iter_t it = _counts.find(std::make_pair(addr, size));

  if(it == _counts.end()) {

    _counts.insert(std::make_pair(std::make_pair(addr, size), std::make_pair(1, 0)));

  } else {

    (*it).second.first += 1;

  }

}

void Region::write(uintptr_t addr, int32_t size)
{
  iter_t it = _counts.find(std::make_pair(addr, size));

  if(it == _counts.end()) {
    _counts.insert(std::make_pair(std::make_pair(addr, size), std::make_pair(0, 1)));
  } else {
    (*it).second.second += 1;
  }
}

void Region::reset()
{
  _counts.clear();
  _count++;
}

Regions::~Regions()
{
  this->close();
}

void Regions::filename(const std::string& file_name)
{
  _file_name = file_name;
}

void Regions::close()
{
  // Ignore data from unfinished regions
  log_file.close();
  for(iter_t it = _regions.begin(); it != _regions.end(); ++it)
    delete (*it).second;
}

Region* Regions::startRegion(std::string name)
{
  iter_t it = _regions.find(name);

  if(it  == _regions.end()) {

    Region* region = new Region{name};
    _regions.insert(std::make_pair(name, region));
    return region;

  } else {
    return (*it).second;
  }

}

void Regions::endRegion(Region* region)
{
  char counter[17];
  sprintf(counter, "%d", region->_count);
  std::string file = _file_name+ "." + region->_region_name + "." + counter;
  log_file.open(file.c_str(), std::ios::out);
  region->print(log_file);
  region->reset();
  log_file.close();
}


