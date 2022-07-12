
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

KNOB<int> KnobCachelineSize(
  KNOB_MODE_WRITEONCE, "pintool",
  "c", "64", "Specify cacheline size for tracing"
);

KNOB<bool> KnobControllerActivate(
  KNOB_MODE_WRITEONCE, "pintool",
  "controller-activate", "false", "Active controller manager."
);

Regions memory_regions;
Region* current_region;
Region* current_host_region;

const char * ROI_BEGIN = "__memreuse_roi_begin";
const char * ROI_END = "__memreuse_roi_end";
const char * HOST_BEGIN = "__memreuse_host_begin";
const char * HOST_END = "__memreuse_host_end";

static CONTROLLER::CONTROL_MANAGER CONTROL;
bool ENABLED = false;
bool HOST_ENABLED = false;

HostEvent curr_host_event, prev_host_event;

std::vector<HostRegionChange> host_region_changes;

using namespace CONTROLLER;

VOID Handler(EVENT_TYPE ev, VOID* val, CONTEXT* ctxt, VOID* ip, THREADID tid, bool bcast)
{
  switch (ev)
  {
    case EVENT_START:
        ENABLED = 1;
        current_region = memory_regions.start_region("default", KnobCachelineSize.Value());
        break;

    case EVENT_STOP:
        ENABLED = 0;
        memory_regions.end_region(current_region);
        break;

    default:
        ASSERTX(false);
  }
}

VOID start_roi(const char* name)
{
  // Stop the region that we are currently ijn.
  if(current_region) {
    memory_regions.end_region(current_region);
    current_region = nullptr;
  }

  // Start a new region
  current_region = memory_regions.start_region(name, KnobCachelineSize.Value());
  prev_host_event = curr_host_event;
  curr_host_event = HostEvent(name, current_region->count());
  ENABLED = 1;

  // Finish the host region
  if(HOST_ENABLED) {
    memory_regions.end_region(current_host_region);
    current_host_region = nullptr;

    // Update previous host region with information which region follows it.
    if(host_region_changes.size())
      host_region_changes.back().after = curr_host_event;

    // Create new event change
    host_region_changes.push_back(HostEvent(curr_host_event));

  }
}

VOID end_roi(const char* name)
{
  ENABLED = 0;

  // Restart host region after escaping ROI
  if(HOST_ENABLED) {
    current_host_region = memory_regions.start_region("host", KnobCachelineSize.Value());
  }
}

VOID start_host()
{
  HOST_ENABLED = 1;
  current_host_region = memory_regions.start_region("host", KnobCachelineSize.Value());
}

VOID end_host()
{
  HOST_ENABLED = 0;
  if(current_region) {
    memory_regions.end_region(current_region);
    current_region = nullptr;
  }
  memory_regions.end_region(current_host_region);
  current_host_region = nullptr;
}
 
VOID memory_read(VOID* ip, VOID* addr, UINT32 size)
{
  if(ENABLED) {
    current_region->read(reinterpret_cast<uintptr_t>(addr), size);
  } else if(HOST_ENABLED) {
    current_host_region->read(reinterpret_cast<uintptr_t>(addr), size);
  }
}

VOID memory_write(VOID* ip, VOID* addr, UINT32 size)
{
  if(ENABLED) {
    current_region->write(reinterpret_cast<uintptr_t>(addr), size);
  } else if(HOST_ENABLED) {
    current_host_region->write(reinterpret_cast<uintptr_t>(addr), size);
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

	RTN host_begin = RTN_FindByName(img, HOST_BEGIN);
	if(RTN_Valid(host_begin)) {


    RTN_Open(host_begin);

    RTN_InsertCall(
      host_begin, IPOINT_BEFORE, (AFUNPTR)start_host,
      IARG_END
    );

    RTN_Close(host_begin);

	}

	RTN host_end = RTN_FindByName(img, HOST_END);
	if(RTN_Valid(host_end)) {


    RTN_Open(host_end);

    RTN_InsertCall(
      host_end, IPOINT_BEFORE, (AFUNPTR)end_host,
      IARG_END
    );

    RTN_Close(host_end);

	}
}

VOID fini(INT32 code, VOID* v)
{
  if(current_region)
    memory_regions.end_region(current_region);
  if(current_host_region)
    memory_regions.end_region(current_host_region);
  memory_regions.close();
	//LOG_FILE << "eof\n" << std::endl;
	//LOG_FILE.close();

  if(!host_region_changes.empty()) {

    std::string file = KnobOutputFile.Value() + ".host_events";
    std::ofstream of(file.c_str(), std::ios::out);

    // Manual JSON export - C++11 not supported in pintools.
    of << "[\n";

    for(size_t i = 0; i < host_region_changes.size(); ++i) {

      host_region_changes[i].print(of, "  ");

      // JSON does not permit trailing comma
      if(i < host_region_changes.size() - 1)
        of << ",\n";
      else
        of << '\n';
    }

    of << "]\n";

    of.close();
  }
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

  memory_regions.filename(KnobOutputFile.Value());

  current_region = nullptr;
  current_host_region = nullptr;

  CONTROL.RegisterHandler(Handler, 0, FALSE);
  if(KnobControllerActivate.Value()) {
    CONTROL.Activate();
  }
 
  IMG_AddInstrumentFunction(Image, 0);

	TRACE_AddInstrumentFunction(trace, 0);

	PIN_AddFiniFunction(fini, 0);

  PIN_StartProgram();
  
  return 0;
}

