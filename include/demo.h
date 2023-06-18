// libdemo
// Copyright (C) 2023 Ian McFarlane

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#ifndef _LIBDEMO_HEADER
#define _LIBDEMO_HEADER
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void demo_to_json(FILE* demo_file, FILE* out);

#ifdef __cplusplus
}
#endif

#endif
