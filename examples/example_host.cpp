
#include <iostream>
#include <cstring>

#include <memreuse.hpp>

int* arr2;
int size2;

void foo()
{
  __memreuse_roi_begin("foo");
  for(int i = 0; i < size2; ++i)
    arr2[i] = arr2[i] + 2;
  __memreuse_roi_end("foo");
}

void foo_use()
{
  for(int i = 0; i < size2; ++i)
    arr2[i] = arr2[i] + 2;
}

void bar()
{
  __memreuse_roi_begin("bar");
  for(int i = 0; i < size2 / 2; ++i)
    arr2[i] = arr2[i] + 3;
  __memreuse_roi_end("bar");
}

void bar_use()
{
  for(int i = 0; i < size2 / 4; ++i)
    arr2[i] = arr2[i] + 3;
}

int main(int argc, char **argv)
{
  int size = 100;
  int* arr = new int[size];
  std::cout << std::hex << arr << std::endl; 
  memset(arr, 0, sizeof(int) * size);
  //foo2(arr, size);

  size2 = size;
  arr2 = arr;

  __memreuse_host_begin();

  foo();
  // use the same memory outside of the region of interest
  foo_use();
  bar();
  // don't use - expect zero

  foo();
  bar();
  // use the same memory outside of the region of interest
  bar_use();

  __memreuse_host_end();

  delete[] arr;
  return 0;
}

