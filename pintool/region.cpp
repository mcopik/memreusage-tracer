
#include <iomanip>

#include "region.hpp"

void Region::print(std::ofstream & of)
{
  of << "region " << _region_name << " " << _counts.size() << '\n';
  for(iter_t it = _counts.begin(); it != _counts.end(); ++it) {
    of << std::hex << (*it).first << " " << std::dec << (*it).second.first << " " << (*it).second.second << '\n';
  }
}

void Region::read(uintptr_t addr, int32_t size)
{
  iter_t it = _counts.find(addr);

  if(it == _counts.end()) {

    _counts.insert(std::make_pair(addr, std::make_pair(1, 0)));

  } else {

    (*it).second.first += 1;

  }
}

void Region::write(uintptr_t addr, int32_t size)
{
  iter_t it = _counts.find(addr);

  if(it == _counts.end()) {
    _counts.insert(std::make_pair(addr, std::make_pair(0, 1)));
  } else {
    (*it).second.second += 1;
  }
}

void Region::reset()
{
  _counts.clear();
}

Regions::~Regions()
{
  this->close();
}

void Regions::open(const std::string& file_name)
{
  log_file.open(file_name.c_str(), std::ios::out);
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
  region->print(log_file);
  region->reset();
}


