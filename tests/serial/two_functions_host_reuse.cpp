
#include <iostream>
#include <cstring>

#include <memreuse.hpp>

void foo(int* array, int size, int offset)
{
  int i;
  std::cout << "variable: foo_ptr: " << std::hex << &array << std::endl; 
  std::cout << "variable: foo_counter: " << std::hex << &i << std::endl; 
  std::cout << "variable: foo_size: " << std::hex << &size << std::endl; 
  std::cout << "variable: foo_offset: " << std::hex << &offset << std::endl; 
  __memreuse_roi_begin("foo");
  for(i = 0; i < size; ++i)
    array[i] = array[i] + offset;
  __memreuse_roi_end("foo");
}

void bar(int* array, int size, int offset)
{
  int i;
  std::cout << "variable: bar_ptr: " << std::hex << &array << std::endl; 
  std::cout << "variable: bar_counter: " << std::hex << &i << std::endl; 
  std::cout << "variable: bar_size: " << std::hex << &size << std::endl; 
  std::cout << "variable: bar_offset: " << std::hex << &offset << std::endl; 
  __memreuse_roi_begin("bar");
  for(i = 0; i < size / 2; ++i)
    array[i] = array[i] + offset;
  __memreuse_roi_end("bar");
}

int main(int argc, char **argv)
{
  int size = 100;
  int offset = 2;
  int* array = new int[size];
  std::cout << "variable: array: " << std::hex << array << std::endl; 
  memset(array, 0, sizeof(int) * size);

  // In this example, we reuse memory directly 
  __memreuse_host_begin();
  array[0] = array[size - 1] + 1;
  foo(array, size, offset);
  array[99] = array[0] - 1;
  bar(array, size, offset);
  array[0] = array[1] = array[99];
  __memreuse_host_end();

  delete[] array;
  return 0;
}

