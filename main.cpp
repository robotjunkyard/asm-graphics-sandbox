// boilerplate SDL stuff goes here
// actual rendering done in call to 'asmRenderTo', which is
// actually in render.asm

#ifdef __cplusplus
#include <cstdlib>
#else
#include <stdlib.h>
#endif

#include <SDL/SDL.h>
#include <math.h>
#include <stdio.h>

#define UBYTE   unsigned char
#define U16     unsigned short
#define U32     unsigned int

// framerate regulator snippet in main() is from:  http://lazyfoo.net/SDL_tutorials/lesson14/
const int framerate = 60;

const int xres = 1024;  // window x res
const int yres = 768;   // window y res
const int cxres = 256;  // canvas x res
const int cyres = 240;  // canvas y res

extern "C" {
    void asmRenderTo(void* canvasPixelsPtr, int canvasWidth, int canvasHeight);
};

void blitScaled(const SDL_Surface* const src, SDL_Surface* dst)
{
    const int sw = src->w,
	sh = src->h,
	dw = dst->w,
	dh = dst->h;

    for (int dx = 0; dx < dw; dx++)
        for (int dy = 0; dy < dh; dy++)
        {
            const int sx = ((float)dx / (float)dw) * sw;
            const int sy = ((float)dy / (float)dh) * sh;

            ((U32*)(dst->pixels))[(dy*dw)+dx] = ((U32*)(src->pixels))[(sy*sw)+sx];;
        }
}

// leave this here so render.asm can use it if needed
volatile unsigned int timer;
volatile unsigned int frame;
const int bitsPerPixel = 32;
const int bytesPerPixel = bitsPerPixel / 8;

int main ( int argc, char** argv )
{
    timer = 0;
    frame = 0;

    // initialize SDL video
    if ( SDL_Init( SDL_INIT_VIDEO ) < 0 )
    {
        printf( "Unable to init SDL: %s\n", SDL_GetError() );
        return 1;
    }

    // make sure SDL cleans up before exit
    atexit(SDL_Quit);

    // create a new window
    SDL_Surface* screen = SDL_SetVideoMode(xres, yres, bitsPerPixel,
                                           SDL_SWSURFACE
                                           // | SDL_FULLSCREEN
                                           | SDL_DOUBLEBUF
	);

    const SDL_PixelFormat& fmt = *(screen->format);
    SDL_Surface* canvas = SDL_CreateRGBSurface(SDL_SWSURFACE, cxres, cyres, bitsPerPixel,
					       fmt.Rmask, fmt.Gmask, fmt.Bmask, fmt.Amask);

    if ( !screen )
    {
        printf("Unable to set video: %s\n", SDL_GetError());
        return 1;
    }

    // program main loop
    bool done = false;
    while (!done)
    {
        // message processing loop
        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            // check for messages
            switch (event.type)
            {
		// exit if the window is closed
            case SDL_QUIT:
                done = true;
                break;

		// check for keypresses
            case SDL_KEYDOWN:
		// exit if ESCAPE is pressed
                if (event.key.keysym.sym == SDLK_ESCAPE)
                    done = true;
                break;
            }
        }

        // DRAWING STARTS HERE
        // clear screen
        //// SDL_FillRect(screen, 0, SDL_MapRGB(screen->format, 0, 0, 0));

        timer = SDL_GetTicks();
	
	{
	    // call NASM-compiled fun stuffs
	    asmRenderTo(canvas->pixels, canvas->w, canvas->h);

	    // scale virtual canvas to window's actual surface
	    blitScaled(canvas, screen);
	}
	
        timer = SDL_GetTicks() - timer;


        // finally, update the screen
        SDL_Flip(screen);

        if( ( timer < 1000 / framerate ) )
        {
            //Sleep the remaining frame time
            SDL_Delay( ( 1000 / framerate ) - timer );
        }

	frame++;
    } // end main loop

    printf("Bye.\n");
    return 0;
}
