
#ifndef __MEMREUSE_HPP__
#define __MEMREUSE_HPP__

void __memreuse_roi_begin(const char *region);
void __memreuse_roi_end(const char *region);

void __memreuse_host_begin();
void __memreuse_host_end();

#endif

