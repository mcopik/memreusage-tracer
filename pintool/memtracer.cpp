
#include <iostream>
#include <fstream>
#include <string>

#include "pin.H"
#include "control_manager.H"
#include "controller_events.H"

#include "region.hpp"

KNOB<std::string> KnobOutputFile(
  KNOB_MODE_WRITEONCE, "pintool",
  "o", "tracer.out", "Specify filename of the output profile."
);

Regions memory_regions;
Region* current_region;

const char * ROI_BEGIN = "__memreuse_roi_begin";
const char * ROI_END = "__memreuse_roi_end";

static CONTROLLER::CONTROL_MANAGER CONTROL;
bool ENABLED = false;

using namespace CONTROLLER;

VOID Handler(EVENT_TYPE ev, VOID* val, CONTEXT* ctxt, VOID* ip, THREADID tid, bool bcast)
{
  std::cerr << "CONTROL " << ev << std::endl;
  switch (ev)
  {
    case EVENT_START:
        ENABLED = 1;
        current_region = memory_regions.startRegion("default");
        break;

    case EVENT_STOP:
        ENABLED = 0;
        memory_regions.endRegion(current_region);
        break;

    default:
        ASSERTX(false);
  }
}

VOID start_roi(const char* name)
{
  current_region = memory_regions.startRegion(name);
	ENABLED = 1;
}

VOID end_roi(const char* name)
{
	ENABLED = 0;
  memory_regions.endRegion(current_region);
  current_region = nullptr;
}
 
VOID memory_read(VOID* ip, VOID* addr, UINT32 size)
{
  if(ENABLED) {
    current_region->read(reinterpret_cast<uintptr_t>(addr), size);
  }
}

VOID memory_write(VOID* ip, VOID* addr, UINT32 size)
{
  if(ENABLED) {
    current_region->write(reinterpret_cast<uintptr_t>(addr), size);
  }
} 

VOID trace(TRACE trace, VOID* v)
{
	// Visit every basic block in the trace
	for (BBL bbl = TRACE_BblHead(trace); BBL_Valid(bbl); bbl = BBL_Next(bbl)) {

		// For every memory instruction in the block, insert the call
    for(INS ins = BBL_InsHead(bbl); INS_Valid(ins); ins = INS_Next(ins) ) {

			// Source: Pins' pinatrace.cpp

			// Instruments memory accesses using a predicated call, i.e.
			// the instrumentation is called iff the instruction will actually be executed.
			//
			// On the IA-32 and Intel(R) 64 architectures conditional moves and REP
			// prefixed instructions appear as predicated instructions in Pin.
			UINT32 memOperands = INS_MemoryOperandCount(ins);

			for (UINT32 memOp = 0; memOp < memOperands; memOp++) {

				if (INS_MemoryOperandIsRead(ins, memOp)) {
					INS_InsertPredicatedCall(
						ins, IPOINT_BEFORE, (AFUNPTR)memory_read, IARG_INST_PTR,
            IARG_MEMORYOP_EA, memOp,
            IARG_MEMORYOP_SIZE, memOp,
            IARG_END
					);
				}
				if (INS_MemoryOperandIsWritten(ins, memOp)) {
					INS_InsertPredicatedCall(
						ins, IPOINT_BEFORE, (AFUNPTR)memory_write, IARG_INST_PTR,
            IARG_MEMORYOP_EA, memOp,
						IARG_MEMORYOP_SIZE, memOp,
            IARG_END
					);
				}

			}
		}
	}
}

VOID Image(IMG img, VOID *v)
{
	RTN begin = RTN_FindByName(img, ROI_BEGIN);
	if(RTN_Valid(begin)) {

    RTN_Open(begin);

    RTN_InsertCall(
      begin, IPOINT_BEFORE, (AFUNPTR)start_roi,
      IARG_FUNCARG_ENTRYPOINT_VALUE, 0,
      IARG_END
    );

    RTN_Close(begin);
	}

	RTN end = RTN_FindByName(img, ROI_END);
	if(RTN_Valid(end)) {


    RTN_Open(end);

    RTN_InsertCall(
      end, IPOINT_BEFORE, (AFUNPTR)end_roi,
      IARG_FUNCARG_ENTRYPOINT_VALUE, 0,
      IARG_END
    );

    RTN_Close(end);

	}
}

VOID fini(INT32 code, VOID* v)
{
  memory_regions.close();
	//LOG_FILE << "eof\n" << std::endl;
	//LOG_FILE.close();
}


INT32 usage()
{
  std::cerr << "MemReusage Tracer - tracing memory to find reusage across iterations and parallel workers." << std::endl;
  std::cerr << std::endl << KNOB_BASE::StringKnobSummary() << std::endl;
  return -1;
}

int main(int argc, char * argv[])
{
  PIN_InitSymbols();

  if (PIN_Init(argc, argv))
    return usage();

  memory_regions.open(KnobOutputFile.Value());

  CONTROL.RegisterHandler(Handler, 0, FALSE);
  CONTROL.Activate();
 
  IMG_AddInstrumentFunction(Image, 0);

	TRACE_AddInstrumentFunction(trace, 0);

	PIN_AddFiniFunction(fini, 0);

  PIN_StartProgram();
  
  return 0;
}

