#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vdemo.h"    
#include <iostream>
#include <random>

// Define simulation time (in arbitrary time units)
static vluint64_t main_time = 0;  

static int WORDSIZE = 16;

/**
This function is called by Verilator to get the current simulation time
    Output:
        main_time: the current simulation time
*/
double sc_time_stamp() {
    return main_time;
}

struct PipelineItem {
    int iData0;
    int iData1;
    int iData2;
    int cycleFed;
};

/**
This function is called to trigger one clock cycle
   Input:
       dut: the module needs to process the change in the current clock cycle
       tfp: the vcd trace to record the change on the module in the current clock cycle
*/
void toggleClock(Vdemo* dut, VerilatedVcdC* tfp) {
    // calling eval() makes the simulation process the changes and update all the internal logic accordingly
    // writes (or "dumps") the current state of the simulation into a VCD 
    // Rising edge
    dut->iClk = 1;
    dut->eval();
    tfp->dump(main_time++);

    // Falling edge
    dut->iClk = 0;
    dut->eval();
    tfp->dump(main_time++);
}

/**
This function is called to trigger a given number of clock cycles
   Input:
       dut: the module needs to process the change in given clock cycles
       tfp: the vcd trace to record the change on the module in the given clock cycles
       int: how many clock cycles to run
*/
void runCycles(Vdemo* dut, VerilatedVcdC* tfp, int cycles) {
    for (int i = 0; i < cycles; i++) {
        toggleClock(dut, tfp);
    }
}

/**
This function is the main function to run tests on the module
   Input:
       argc: the number of command-line arguments passed to the program
       argv: each element in this array corresponds to one command-line argument
   parameter:
       dut: the device module under test
       tfp: the vcd trace to record the change on the module
       numberTest: the number of test cases
       err: the number of errors that happen in all these test cases
       PIPELINE_LATENCY: the delay of each input in the pipeline
       totalCycles: the total number of clock cycles the module is going to run based on given test cases
*/
int main(int argc, char** argv) {
    // Pass command-line arguments to Verilator
    Verilated::commandArgs(argc, argv);

    // Turn on waveform tracing
    Verilated::traceEverOn(true);

    // Create DUT(Device under test) instance
    Vdemo* dut = new Vdemo;

    // Create VCD trace
    VerilatedVcdC* tfp = new VerilatedVcdC;

    // it allows you to capture and view waveforms of internal signals up to 99 levels deep in your module hierarchy
    dut->trace(tfp, 99);      
    tfp->open("demoWaveform.vcd");      // Waveform output file

    runCycles(dut, tfp, 1);
    dut->iClk    = 0;
    dut->iRstN   = 0;  
    dut->iData0  = 0;
    dut->iData1  = 0;
    dut->iData2  = 0;

    std::cout << "[INFO] Applying reset...\n";
    runCycles(dut, tfp, 1);

    std::cout << "[INFO] Releasing reset...\n";
    dut->iRstN = 1;
    runCycles(dut, tfp, 1);
    
    int numberTest = 10000;
    int err = 0;

    std::srand(static_cast<unsigned>(std::time(nullptr)));

    // Format: { iData0, iData1, iData2 }
    // Each sub-array is one test case
    // Create a 1000x3 vector with random values between -16383 to 16384 (14 bits) 
    // sum of 14 bits numbers will be in the range of 15 bits
    std::vector<std::vector<int>> testVectors;
    testVectors.reserve(numberTest);
    for (int i = 0; i < numberTest; ++i) {
        std::vector<int> row;
        row.reserve(3);
        for (int j = 0; j < 3; ++j) {
            int value = (std::rand() % 32768) - 16383; // Random number in the range of -16383 to 16384 (14 bits) 
            row.push_back(value);
        }
        testVectors.push_back(row);
    }

    // Create sumVectors by adding the first element and the minimum of the last two elements
    std::vector<int> sumVectors;
    sumVectors.reserve(testVectors.size());
    for (const auto& row : testVectors) {
        // using c++ to compute the result to test the module later
        int sum = row[0] + std::min(row[1], row[2]);
        sumVectors.push_back(sum);
    }


    std::queue<PipelineItem> pending;

    const int PIPELINE_LATENCY = 1;

    int totalCycles = testVectors.size() + PIPELINE_LATENCY + 2;

    // index into testVectors
    int tvIndex = 0; 

    // Apply each test case
    for (int cycle = 0; cycle < totalCycles; cycle++) {
        if (tvIndex < (int)testVectors.size()) {
            dut->iData0  = testVectors[tvIndex][0];
            dut->iData1  = testVectors[tvIndex][1];
            dut->iData2  = testVectors[tvIndex][2];

            // Allow the DUT to process for a few cycles so that outputs can match with the correct inputs
            PipelineItem item;
            item.iData0  = testVectors[tvIndex][0];
            item.iData1  = testVectors[tvIndex][1];
            item.iData2  = testVectors[tvIndex][2];
            item.cycleFed  = cycle;
            pending.push(item);

            tvIndex++;
        } else {
            dut->iData0  = 0;
            dut->iData1  = 0;
            dut->iData2  = 0;
        }
        
        toggleClock(dut, tfp);

        if (!pending.empty()) {
            // If the current cycle == (cycleFed + latency)
            // we should see the result for that input
            // the pending is a queue, we can have each test case one by one use .front()
            auto& frontItem = pending.front();
            if (cycle == frontItem.cycleFed + PIPELINE_LATENCY) {
                std::cout << "===== Output for input fed at cycle "
                        << frontItem.cycleFed << " =====\n"
                        << "  Input was: \n"
                        << "  iData0  = " << frontItem.iData0 << "\n"
                        << "  iData1  = " << frontItem.iData1 << "\n"
                        << "  iData2  = " << frontItem.iData2 << "\n"
                        << "  ----------------------------------"
                        << "  Output was: \n"
                        << std::endl;
                    // comparing with the result computed by C++
                    if (int(dut->sum) >= (1 << (WORDSIZE - 1))) {
                        // Adjust for two's complement representation
                        int signed_value = int(dut->sum) - (1 << WORDSIZE);
                        if (signed_value != sumVectors[frontItem.cycleFed]) {
                            err++;
                        }
                        std::cout << "  sum  = " << signed_value<< "\n";
                    } else {
                        std::cout << "  sum  = " << int(dut->sum)<< "\n";
                        if (int(dut->sum) != sumVectors[frontItem.cycleFed]) {
                            err++;
                        }
                    }
                pending.pop();
            }
        }
    }

    std::cout << "  number of errors  = " << err << "\n";
    tfp->close();      // close VCD
    dut->final();      // model cleanup
    delete dut;        
    delete tfp;
    return 0;
}