# Makefile for building LODA BOINC server programs
# like validators and assimilators

all: loda_validator loda_assimilator

CFLAGS = -g -Wall

BOINC = /usr/local/boinc

LIBS = $(BOINC)/sched/libsched.a $(BOINC)/lib/libboinc.a \
    -lmysqlclient

INC = -I $(BOINC) -I $(BOINC)/lib -I $(BOINC)/sched -I $(BOINC)/db \
      -I /usr/include/mysql

CXX = g++ $(CFLAGS) $(INC)

VALIDATOR_OBJS = $(BOINC)/sched/validator.o \
    $(BOINC)/sched/validate_util.o \
    $(BOINC)/sched/validate_util2.o

ASSIMILATOR_OBJS = $(BOINC)/sched/assimilator.o \
    $(BOINC)/sched/validate_util.o

.cpp.o:
	$(CXX) -c -o $*.o $<

loda_validator: loda_validator.cpp
	$(CXX) loda_validator.cpp $(VALIDATOR_OBJS) $(LIBS) -o loda_validator

loda_assimilator: loda_assimilator.cpp
	$(CXX) loda_assimilator.cpp $(ASSIMILATOR_OBJS) $(LIBS) -o loda_assimilator
