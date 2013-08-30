#!/usr/bin/env perl

use v5.14;
use FindBin '$Bin';
use lib "$Bin";

use PhotoDateFixer;
PhotoDateFixer->run;
