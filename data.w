@* Header Inclusion, Structs, and Macros.

@ \subsec{Header of File}
The header section consists of header inclusion, and definition of C-structs. 
The system-wide header files include |stdlib.h| for things like |malloc()|.
Standard math library functions from |math.h| are used. 
Soundpipe/Sporth specific header files are |soundpipe.h| and |sporth.h|.
It should be noted that due to the implementation of Sporth, the Soundpipe
header file {\it must} be included before the Sporth header file.

ANSI C doesn't have the constant |M_PI|, so it has to be explicitly defined.

Both |MIN| and |MAX| macros are defined.

The header file |string.h| is included so that |memset| can be used to 
zero arrays.

There is exactly one local header file called |voc.h|, which
is generated by CTANGLE. For more information about this header file, 
see |@<voc.h@>|

The macro |MAX_TRANSIENTS| is the maximum number of transients at a given
time.

@<Headers@>=
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "soundpipe.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#include "voc.h"

#ifndef MIN
#define MIN(A,B) ((A) < (B) ? (A) : (B))
#endif

#ifndef MAX
#define MAX(A,B) ((A) > (B) ? (A) : (B))
#endif

#define EPSILON 1.0e-38

#define MAX_TRANSIENTS 4

@<Data Structures...@>

@ \subsec{Structs} 
This subsection contains all the data structs needed by Voc.

@<Data Structures and C Structs@>=
@<Glottis Data...@>@/
@<Transient Data...@>@/
@<Tract Data...@>@/
@<Utilities...@>@/
@<Voc Main...@>@/

@ The top-most data structure is |sp_voc|, designed to be an opaque
struct containing all the variables needed for {\it Voc} to work. 
Like all Soundpipe modules, this struct has the prefix "sp". 

@<Voc Main Data Struct@>=

struct sp_voc {
    glottis @, glot; /*The Glottis*/
    tract @, tr; /*The Vocal Tract */
    SPFLOAT @, buf[512];
    int counter;
};

@ The glottis data structure contains all the variables used by the glottis.
See |@<The Glottis@>| to see the implementation of the glottal sound source.

\item{$\bullet$} |enable| is the on/off state of the glottis
\item{$\bullet$} |freq| is the frequency
\item{$\bullet$} |tenseness| is the tenseness of the glottis (more or less looks
like a cross fade between voiced and unvoiced sound). It is a value in the
range $[0,1]$.
\item{$\bullet$} |intensity| is an internal value used for applying attack and
release on |enable| transitions
\item{$\bullet$} |attack_time| is the time in seconds to reach full amplitude
following glottis on
\item{$\bullet$} |release_time| is the time in seconds to reach 0 amplitude
following glottis off
\item{$\bullet$} |Rd| % is what?
\item{$\bullet$} |waveform_length| provides the period length (in seconds) of
the fundamental frequency, in seconds.
\item{$\bullet$} The waveform position is kept track of in |time_in_waveform|,
in seconds.

% TODO: describe what these variables are
\item{$\bullet$} |alpha|
\item{$\bullet$} |E0|
\item{$\bullet$} |epsilon|
\item{$\bullet$} |shift|
\item{$\bullet$} |delta|
\item{$\bullet$} |Te|
\item{$\bullet$} |omega|
\item{$\bullet$} |T|

@<Glottis Data Structure@>=

typedef struct {
    int @, enable;
    SPFLOAT @, freq; 
    SPFLOAT @, tenseness; 
    SPFLOAT @, intensity;
    SPFLOAT @, attack_time;
    SPFLOAT @, release_time;
    SPFLOAT @, Rd; 
    SPFLOAT @, waveform_length; 
    SPFLOAT @, time_in_waveform;

    SPFLOAT @, alpha;
    SPFLOAT @, E0;
    SPFLOAT @, epsilon;
    SPFLOAT @, shift;
    SPFLOAT @, delta;
    SPFLOAT @, Te;
    SPFLOAT @, omega;

    SPFLOAT @, T;
} glottis;

@
@<Transient Data@>=
@<A Single Transient@>@/
@<The Transient Pool@>

@ This data struct outlines the data for a single transient. A transient 
will act as a single entry in a linked list implementation, so there exists
a |next| pointer along with the |SPFLOAT| parameters.

@<A Single Transient@>=
typedef struct transient {
    int @, position;
    SPFLOAT @, time_alive;
    SPFLOAT @, lifetime;
    SPFLOAT @, strength;
    SPFLOAT @, exponent;
    char is_free;
    unsigned int id;
    struct transient *next;
} transient;

@ A pre-allocated set of transients and other parameters are used in what
will be known as a {\it transient pool}. A memory pool is an ideal choice for 
realtime systems instead of dynamic memory. Calls to |malloc| are discouraged
because it adds performance overhead and possible blocking behavior, and there 
is a greater chance of memory leaks or segfaults if not handled properly. 


@<The Transient Pool@>=
typedef struct {
    transient pool[MAX_TRANSIENTS];
    transient *root;
    int size;
    int next_free;
} transient_pool;

@ The Tract C struct contains all the data needed for the vocal tract filter.
@<Tract Data@>=
typedef struct {
    int n; 
    @t \indent n is the size, set to 44. @> @/
    SPFLOAT @, diameter[44];
    SPFLOAT @, rest_diameter[44];
    SPFLOAT @, target_diameter[44];
    SPFLOAT @, new_diameter[44];
    SPFLOAT @, R[44]; @t \indent component going right @>@/
    SPFLOAT @, L[44]; @t \indent component going left @>@/
    SPFLOAT @, reflection[45];
    SPFLOAT @, new_reflection[45];
    SPFLOAT @, junction_outL[45];
    SPFLOAT @, junction_outR[45];
    SPFLOAT @, A[44];
    
    int nose_length; 
@t \indent The original code here has it at $floor(28 * n/44)$, and since @>
@t n=44, it should be 28.@>@/
    int nose_start; @t \indent $n - nose\_length + 1$, or 17 @>@/
@t tip\_start is a constant set to 32 @>@/
    int tip_start;
    SPFLOAT @, noseL[28];
    SPFLOAT @, noseR[28];
    SPFLOAT @, nose_junc_outL[29];
    SPFLOAT @, nose_junc_outR[29];
    SPFLOAT @, nose_reflection[29];
    SPFLOAT @, nose_diameter[28];
    SPFLOAT @, noseA[28];

    SPFLOAT @, reflection_left;
    SPFLOAT @, reflection_right;
    SPFLOAT @, reflection_nose;
    
    SPFLOAT @, new_reflection_left;
    SPFLOAT @, new_reflection_right;
    SPFLOAT @, new_reflection_nose;

    SPFLOAT @, velum_target;

    SPFLOAT @, glottal_reflection;
    SPFLOAT @, lip_reflection;
    int @, last_obstruction;
    SPFLOAT @, fade;
    SPFLOAT @, movement_speed; @t 15 cm/s @>@\
    SPFLOAT @, lip_output;
    SPFLOAT @, nose_output;
    SPFLOAT @, block_time;

    transient_pool tpool;
    SPFLOAT @, T;
} tract;

@
@<Utilities@>=

static SPFLOAT move_towards(SPFLOAT current, SPFLOAT target,
        SPFLOAT amt_up, SPFLOAT amt_down)
{
    SPFLOAT tmp;
    if(current < target) {
        tmp = current + amt_up;
        return MIN(tmp, target);
    } else {
        tmp = current - amt_down;
        return MAX(tmp, target);
    }
}
