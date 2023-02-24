#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "boinc_db.h"
#include "error_numbers.h"
#include "filesys.h"
#include "sched_msgs.h"
#include "validate_util.h"
#include "sched_config.h"
#include "assimilate_handler.h"

// see https://boinc.berkeley.edu/trac/wiki/AssimilateIntro

int assimilate_handler_init(int argc, char** argv) {
    return 0;
}

void assimilate_handler_usage() {
}

const std::string OUT_DIR("errors");

int assimilate_handler(
    WORKUNIT& wu, std::vector<RESULT>& results, RESULT& canonical_result) {
    char buf[1024];
    auto retval = boinc_mkdir(config.project_path(OUT_DIR.c_str()));
    if (retval) {
        return retval;
    }
    if (!wu.canonical_resultid) {
        std::vector<OUTPUT_FILE_INFO> output_files;
        const char *copy_path;
        get_output_file_infos(canonical_result, output_files);
        int n = output_files.size();
        bool file_copied = false;
        for (int i=0; i<n; i++) {
            OUTPUT_FILE_INFO& fi = output_files[i];
            if (n==1) {
                sprintf(buf, "%s/%s", OUT_DIR.c_str(), wu.name);
            } else {
                sprintf(buf, "%s/%s_%d", OUT_DIR.c_str(), wu.name, i);
            }
            copy_path = config.project_path(buf);
            retval = boinc_copy(fi.path.c_str() , copy_path);
            if (!retval) {
                file_copied = true;
            }
        }
        if (!file_copied) {
            std::ofstream out(OUT_DIR + "/no_output_files", std::fstream::app);
            out << std::string(wu.name) << std::endl;
        }
    }
    return 0;
}
