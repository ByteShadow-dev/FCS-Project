load .,
output-file RunDemo.out,
output-list VM;

repeat 200000 {
  vmstep;
}