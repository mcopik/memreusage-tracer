
#include "memreuse.hpp"

void __memreuse_roi_begin(const char *region)
{
  asm volatile("" : : : "memory");
}

void __memreuse_roi_end(const char *region)
{
  asm volatile("" : : "g"(region) : "memory");
}

void __memreuse_host_begin()
{
  asm volatile("" : : : "memory");
}

void __memreuse_host_end()
{
  asm volatile("" : : : "memory");
}

