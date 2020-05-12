#define SKIP_applet_main
#define ALIGN1
#define ALIGN2
#include <stdio.h>
#include <stdint.h>
#include "include/applet_tables.h"
int main() {
  for(const char*s=applet_names;*s||*(s+1);s++) { 
    putchar(*s?*s:'\n'); } }
