#!/usr/bin/gnuplot
set terminal postscript enhanced color
set terminal postscript enhanced size 6in,3in
set format y "%.2f"
set   autoscale                        # scale axes automatically
unset log                              # remove any log-scaling
unset label                            # remove any previous labels

#set border 3
#set mytics 2
#set mxtics 1
#set ytics font ",20"
#set xtics font ",20"
#set xtics 200,100,1000
#set key font ",20"
#set key top right
#set key spacing 3.5

set ylabel 'Energie [E_h]'
set xlabel 'Anzahl Monte Carlo Schritte'
set encoding iso_8859_1
set xtics out
set ytics out
set xtics nomirror
set ytics nomirror
set output 'data.eps'
set nokey
#set title 'Resonanzenergie'

plot 'data.dat' using 1:2 with line
