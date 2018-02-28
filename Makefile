CC = mpicc
CXX = mpicxx
LDFLAGS = -lm -fopenmp -llodepng
CXXFLAGS = -O3 -std=c++11 -I/home/ipc/ta/lib/glm -I/home/ipc/ta/lib/lodepng -L/home/ipc/ta/lib/lodepng -I/home/ipc/zexlus1126/hw2_judge/src/json/include
TARGETS = md_diff summary

.PHONY: all
all: $(TARGETS)

%: src/%.cc
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS) $(SOURCES)

.PHONY: clean
clean:
	rm -f $(TARGETS) $(TARGETS:=.o)
