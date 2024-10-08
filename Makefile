CC     = gcc     # the c compiler to use
MPICC  = mpicc   # the MPI cc compiler
CFLAGS = -O3     # optimize code
DFLAGS =         # common defines
LIB    = -lm     # link libraries
THREADS = 2 4 8 16 32
PROCS = 2 4 8 16 32 64 128
ARGS_WEAK = 10000000 10
ARGS_STRONG = 100000000 10

default: run

all: prefixsum_seq prefixsum_omp prefixsum_mpi 

prefixsum_seq: prefixsum_seq.c
	$(CC) $(CFLAGS) $(DFLAGS) $(LIB) -o $@ $<

prefixsum_omp: prefixsum_omp.c
	$(CC) $(CFLAGS) $(DFLAGS) $(LIB) -fopenmp -o $@ $<

prefixsum_mpi: prefixsum_mpi.c
	$(MPICC) $(CFLAGS) $(DFLAGS) $(LIB) -o $@ $<

run: run_prefixsum_seq run_prefixsum_omp run_prefixsum_mpi 

run_prefixsum_seq: prefixsum_seq
	bsub -q cpu -J prefixsum_seq_weak -n 1 -o prefixsum_seq_weak_output.log -e prefixsum_seq_weak_error.log "./prefixsum_seq 10000000 10"
	bsub -q cpu -J prefixsum_seq_strong -n 1 -o prefixsum_seq_strong_output.log -e prefixsum_seq_strong_error.log "./prefixsum_seq 100000000 10"

run_prefixsum_omp: prefixsum_omp
	$(foreach t, $(THREADS), \
		bsub -q cpu -J prefixsum_omp_weak -n $(t) \
		-o prefixsum_omp_weak_$(t)threads_output.log \
		-e prefixsum_omp_weak_$(t)threads_error.log \
		"./prefixsum_omp $(ARGS_WEAK) $(t)";)
	$(foreach t, $(THREADS), \
		bsub -q cpu -J prefixsum_omp_strong -n $(t) \
		-o prefixsum_omp_strong_$(t)threads_output.log \
		-e prefixsum_omp_strong_$(t)threads_error.log \
		"./prefixsum_omp $(ARGS_STRONG) $(t)";)

run_prefixsum_mpi: prefixsum_mpi
	$(foreach t, $(PROCS), \
		bsub -q cpu -J prefixsum_mpi_weak -n $(t) \
		-o prefixsum_mpi_weak_$(t)threads_output.log \
		-e prefixsum_mpi_weak_$(t)threads_error.log \
		"module load openmpi/4.1.5 && mpirun -np $(t) ./prefixsum_mpi $(ARGS_WEAK)";)
	$(foreach t, $(PROCS), \
		bsub -q cpu -J prefixsum_mpi_strong -n $(t) \
		-o prefixsum_mpi_strong_$(t)threads_output.log \
		-e prefixsum_mpi_strong_$(t)threads_error.log \
		"module load openmpi/4.1.5 && mpirun -np $(t) ./prefixsum_mpi $(ARGS_STRONG)";)

clean:
	rm prefixsum_seq prefixsum_omp prefixsum_mpi

clean_report:
	rm -f ./*.txt ./*.log
