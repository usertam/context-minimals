set term context size 5in,3in standalone
set output "fullpage-example.tex"
plot sin(x)
plot cos(atan(x))*sin(x)
