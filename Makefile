CC = mpicc
CXX = mpicxx
LDFLAGS = -lm -fopenmp -llodepng
CFLAGS = -O3 -std=gnu99 -I/home/ipc/ta/lib/lodepng -L/home/ipc/ta/lib/lodepng
CXXFLAGS = -O3 -std=c++11 -I/home/ipc/ta/lib/glm -I/home/ipc/ta/lib/lodepng -L/home/ipc/ta/lib/lodepng
TARGETS = md_diff

.PHONY: all
all: $(TARGETS)

%: src/%.cc
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS) $(SOURCES)

.PHONY: clean
clean:
	rm -f $(TARGETS) $(TARGETS:=.o)
