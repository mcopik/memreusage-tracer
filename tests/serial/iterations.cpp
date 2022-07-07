
#include <iostream>
#include <cstring>

#include <memreuse.hpp>

void foo(int* array, int size, int offset)
{
  int i;
  std::cout << "variable: ptr: " << std::hex << &array << std::endl; 
  std::cout << "variable: counter: " << std::hex << &i << std::endl; 
  std::cout << "variable: size: " << std::hex << &size << std::endl; 
  std::cout << "variable: offset: " << std::hex << &offset << std::endl; 
  __memreuse_roi_begin("foo");
  for(i = 0; i < size; ++i)
    array[i] = array[i] + offset;
  __memreuse_roi_end("foo");
}

int main(int argc, char **argv)
{
  int size = 100;
  int offset = 2;
  int* array = new int[size];
  std::cout << "variable: array: " << std::hex << array << std::endl; 
  memset(array, 0, sizeof(int) * size);

  // Call with varying number of array accesses in each call.
  for(int i = 0; i < 5; ++i)
    foo(array, i, offset);

  delete[] array;
  return 0;
}

