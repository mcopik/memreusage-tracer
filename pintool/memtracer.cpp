
#include <iostream>
#include <fstream>
#include <string>

#include "pin.H"
#include "control_manager.H"
#include "controller_events.H"

KNOB<std::string> KnobOutputFile(
  KNOB_MODE_WRITEONCE, "pintool",
  "o", "tracer.out", "Specify filename of the output profile."
);

std::ofstream LOG_FILE;
PIN_LOCK OutFileLock;

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
        break;

    case EVENT_STOP:
        ENABLED = 0;
        break;

    default:
        ASSERTX(false);
  }
}
 
VOID memory_read(VOID* ip, VOID* addr, UINT32 size)
{
  if(ENABLED)
    LOG_FILE << "R " << addr << " " << size << '\n';
}

VOID memory_write(VOID* ip, VOID* addr, UINT32 size)
{
  if(ENABLED)
    LOG_FILE << "W " << addr << " " << size << '\n';
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
 
VOID fini(INT32 code, VOID* v)
{
	LOG_FILE << "eof\n" << std::endl;
	LOG_FILE.close();
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

  LOG_FILE.open(KnobOutputFile.Value().c_str(), std::ios::out);

  CONTROL.RegisterHandler(Handler, 0, FALSE);
  CONTROL.Activate();
 
	TRACE_AddInstrumentFunction(trace, 0);

	PIN_AddFiniFunction(fini, 0);

  PIN_StartProgram();
  
  return 0;
}

