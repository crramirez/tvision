/* Declarations for getopt.
   Copyright (C) 1989, 1990, 1991, 1992, 1993 Free Software Foundation, Inc.
   Copyright (C) 2000, 01, 2002 Salvador E. Tropea.

   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 2, or (at your option) any
   later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.  */

#ifndef HEADER_GETOPT_H
#define HEADER_GETOPT_H 1

#ifdef	__cplusplus
extern "C" {
#endif

/* For communication from `getopt' to the caller.
   When `getopt' finds an option that takes an argument,
   the argument value is returned here.
   Also, when `ordering' is RETURN_IN_ORDER,
   each non-option ARGV-element is returned here.  */

extern char *CLY_optarg;

/* Index in ARGV of the next element to be scanned.
   This is used for communication to and from the caller
   and for communication between successive calls to `getopt'.

   On entry to `getopt', zero means this is the first call; initialize.

   When `getopt' returns EOF, this is the index of the first of the
   non-option elements that the caller should itself scan.

   Otherwise, `optind' communicates from one call to the next
   how much of ARGV has been scanned so far.  */

extern int CLY_optind;

/* Callers store zero here to inhibit the error message `getopt' prints
   for unrecognized options.  */

extern int CLY_opterr;

/* Set to an option character which was unrecognized.  */

extern int CLY_optopt;

/* Describe the long-named options requested by the application.
   The LONG_OPTIONS argument to getopt_long or getopt_long_only is a vector
   of `struct option' terminated by an element containing a name which is
   zero.

   The field `has_arg' is:
   no_argument       (or 0) if the option does not take an argument,
   required_argument (or 1) if the option requires an argument,
   optional_argument (or 2) if the option takes an optional argument.

   If the field `flag' is not NULL, it points to a variable that is set
   to the value given in the field `val' when the option is found, but
   left unchanged if the option is not found.

   To have a long-named option do something other than set an `int' to
   a compiled-in constant, such as set a value from `optarg', set the
   option's `flag' field to zero and its `val' field to a nonzero
   value (the equivalent single-letter option character, if there is
   one).  For long options that have a zero `flag' field, `getopt'
   returns the contents of the `val' field.  */

struct CLY_option
{
  const char *name;
  /* has_arg can't be an enum because some compilers complain about
     type mismatches in all the code that assumes it is an int.  */
  int has_arg;
  int *flag;
  int val;
};

/* Names for the values of the `has_arg' field of `struct option'.  */

#define CLY_no_argument        0
#define CLY_required_argument  1
#define CLY_optional_argument  2

extern int CLY_getopt(int argc, char *const *argv, const char *shortopts);
extern int CLY_getopt_long(int argc, char *const *argv, const char *shortopts,
                           const struct option *longopts, int *longind);
extern int CLY_getopt_long_only(int argc, char *const *argv,
                                const char *shortopts,
                                const struct option *longopts, int *longind);
/* Internal only.  Users should not call this directly.  */
extern int CLY_getopt_internal(int argc, char *const *argv,
                               const char *shortopts,
                               const struct option *longopts, int *longind,
                               int long_only);

#ifdef __cplusplus
}
#endif

#endif /* HEADER_GETOPT_H */
