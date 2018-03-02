CXX = g++
LDFLAGS = -lm -fopenmp -llodepng
CXXFLAGS = -O3 -std=c++11 -I/home/ipc/ta/lib/glm -I/home/ipc/ta/lib/lodepng -L/home/ipc/ta/lib/lodepng -I/home/ipc/ta/lib/json/include
TARGETS = md_diff json_summary

.PHONY: all
all: $(TARGETS)

%: src/%.cc
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS) $(SOURCES)

.PHONY: clean
clean:
	rm -f $(TARGETS) $(TARGETS:=.o)
