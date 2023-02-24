#include <vector>

#include "sched_msgs.h"
#include "sched_util_basic.h"
#include "validate_util.h"
#include "validate_util2.h"
#include "validator.h"

#include <fstream>
#include <iostream>

// see https://boinc.berkeley.edu/trac/wiki/ValidationSimple

int validate_handler_init(int argc, char** argv) {
    return 0;
}

void validate_handler_usage() {
}

int init_result(RESULT& result, void*& data) {
    OUTPUT_FILE_INFO fi;
    auto retval = get_output_file_path(result, fi.path);
    if (retval) {
        return retval;
    }
    bool finished = false, slow = false, alert = false;
    std::ifstream in(fi.path);
    if (in) {
        std::string line;
        while (std::getline(in, line)) {
            if (line.find("Finished mining") != std::string::npos) {
                finished = true;
            }
            if (line.find("Slow processing") != std::string::npos) {
                slow = true;
            }
            if (line.find("ALERT") != std::string::npos) {
                alert = true;
            }
        }
        in.close();
    }
    if (!finished && !slow && !alert) {
        return 3; // permanent error
    }
    bool* b = new bool(true);
    data = (void*) b;
    return 0;
}

int compare_results(RESULT&, void*, RESULT const&, void*, bool& match) {
    match = true;
    return 0;
}

int cleanup_result(RESULT const&, void*) {
    return 0;
}
