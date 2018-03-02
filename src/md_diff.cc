#include <iostream>
#include <string>
#include <cstdio>
#include <cstdlib>
#include <cassert>
#include <cmath>

#include <lodepng.h>
#include <omp.h>

#include "ascii_font.h"

#define max(a, b) ((a)>(b) ? (a):(b))
#define min(a, b) ((a)<(b) ? (a):(b))
#define clamp(a, b, c)  ((a)>(b) ? ((a)<(c)?(a):(c)):(b))

int miss_sum_thres = 70;
int miss_max_thres = 30;

struct Image{
    unsigned char *raw_image;
    unsigned char **image;
    unsigned width, height;
    bool hasImage;

    Image(){ hasImage = false; }
    Image(std::string filename){
        hasImage = false;
        load(filename);
    }

    Image(unsigned width, unsigned height) : width(width), height(height){
        raw_image = new unsigned char[width*height*4]{};
        image = new unsigned char*[height];

        for(int i=0;i<height;++i){
            image[i] = raw_image + i*width*4;
        }

        hasImage = true;
    }

    ~Image(){
        clear();
    }

    bool load(std::string filename){
        unsigned error;
        error = lodepng_decode32_file(&raw_image, &width, &height, filename.c_str());
        if(error){
            printf("[ERROR] Image [%s] load error %u: %s\n", filename.c_str(), error, lodepng_error_text(error));
            return false;
        }
        
        image = new unsigned char*[height];
        for(int i=0;i<height;++i){
            image[i] = raw_image + i*width*4;
        }

        return hasImage = true;
    }

    bool save(std::string filename){
        unsigned error = lodepng_encode32_file(filename.c_str(), raw_image, width, height);
        if(error){
            printf("[ERROR] Image [%s] save error %u: %s\n", filename.c_str(), error, lodepng_error_text(error));
        }
    }

    void clear(){
        if(hasImage){
            delete[] raw_image;
            delete[] image;
        }
        hasImage = false;
    }

    unsigned char* operator[](unsigned idx){
        return image[idx];
    }
};

std::string *get_font(std::string font_name, int grade){
    if(font_name == "ansi_shadow"){
        return ansi_shadow[grade];
    }
}

void print_fc_font(std::string font_name){
    if(font_name == "fire"){
        for(int i=0;i<8;++i){
            printf("%s\n", fire_fullcombo[i].c_str());
        }
    }else if(font_name == "slant"){
        for(int i=0;i<5;++i){
            printf("%s\n", slant_fullcombo[i].c_str());
        }
    }
}

void check_pixel(unsigned char *colA, unsigned char *colB, unsigned &diff, unsigned &max_diff)
{
    diff = 0;
    max_diff = 0;
    diff += abs(colA[0]-colB[0]);
    diff += abs(colA[1]-colB[1]);
    diff += abs(colA[2]-colB[2]);
    max_diff = max(max_diff, colA[0]-colB[0]);
    max_diff = max(max_diff, colA[1]-colB[1]);
    max_diff = max(max_diff, colA[2]-colB[2]);
}

int main(int argc, char **argv){
    assert(argc == 3 || argc == 4);
    
    Image A, B;

    if(!A.load(argv[1])){
        fprintf(stderr, "[ERROR] Image [%s] load error\n", argv[1]);
        exit(255);
    }

    if(!B.load(argv[2])){
        fprintf(stderr, "[ERROR] Image [%s] load error\n", argv[2]);
        exit(254);
    }

    if(A.width != B.width || A.height != B.height){
        fprintf(stderr, "[ERROR] Two images have differet sizes:\n");
        fprintf(stderr, "        Image A: (%u, %u)\n", A.width, A.height);
        fprintf(stderr, "        Image B: (%u, %u)\n", B.width, B.height);
        exit(253);
    }

    //////check
    unsigned total_pixel = A.width*A.height;
    unsigned perfect = 0;
    unsigned good = 0;
    unsigned miss = 0;

    unsigned int end = total_pixel * 4;

    if(argc == 3){

        for(unsigned int offset=0; offset < end; offset += 4){
            unsigned diff = 0;
            unsigned max_diff = 0;
            unsigned char *colA = &A[0][0] + offset;
            unsigned char *colB = &B[0][0] + offset;

            check_pixel(colA, colB, diff, max_diff);

            if(diff == 0){
                perfect += 1;
            }else if(diff <= miss_sum_thres && max_diff <= miss_max_thres){
                good += 1;
            }else{
                miss += 1;
            }
        }
    }else{

        Image diff_image(A.width, A.height);

        for(unsigned int offset=0; offset < end; offset += 4){
            unsigned diff = 0;
            unsigned max_diff = 0;
            unsigned char *colA = &A[0][0] + offset;
            unsigned char *colB = &B[0][0] + offset;
            
            check_pixel(colA, colB, diff, max_diff);

            unsigned char gray;
            gray = ((int)colA[0] * 299 + (int)colA[1] * 587 + (int)colA[2] * 114)/1000;

            unsigned char *colC = &diff_image[0][0] + offset;
            if(diff == 0){
                perfect += 1;
                colC[0] = gray/2;
                colC[1] = gray/2;
                colC[2] = gray/2;
                colC[3] = 255;
            }else if(diff <= miss_sum_thres && max_diff <= miss_max_thres){
                good += 1;
                colC[0] = gray/2;
                colC[1] = (gray+255)/2;
                colC[2] = gray/2;
                colC[3] = 255;
            }else{
                miss += 1;
                colC[0] = (gray+255)/2;
                colC[1] = gray/2;
                colC[2] = gray/2;
                colC[3] = 255;
            }

        }

        diff_image.save(argv[3]);
    }

    double perfect_rate = (double)perfect / (double)total_pixel * 100.0;
    double good_rate = (double)good / (double)total_pixel * 100.0;
    double miss_rate = (double)miss / (double)total_pixel * 100.0;
    double accuracy = ((double)perfect + 0.5 * (double)good)/(double)total_pixel * 100.0 - 0.005;

    bool fullcombo = false;

    std::string grade_str = "X";
    
    if(perfect == total_pixel){  //SS
        fullcombo = true;
        grade_str = "SS";
    }else if(miss == 0 && accuracy > 99.6){  //S
        fullcombo = true;
        grade_str = "S";
    }else if(accuracy > 99.6){  //A
        grade_str = "A";
    }else if(accuracy > 99.){  //B
        grade_str = "B";
    }else if(accuracy > 95.){  //C
        grade_str = "C";
    }else{                     //F
        grade_str = "F";
    }

    /*
    std::string *font = get_font("ansi_shadow", grade);

    printf("\n");
    printf("       Result        |       Rank      \n");
    printf("---------------------+-----------------\n");
    printf("  \033[36mPerfect\033[0m:           | %15s \n", font[0].c_str());
    printf("  \033[33m%18u\033[0m | %15s \n",      perfect, font[1].c_str());
    printf("---------------------+ %15s \n", font[2].c_str());
    printf("  \033[32mGood\033[0m:              | %15s \n", font[3].c_str());
    printf("  \033[33m%18u\033[0m | %15s \n",         good, font[4].c_str());
    printf("---------------------+ %15s \n", font[5].c_str());
    printf("  \033[31mMiss\033[0m:              | %15s \n", font[6].c_str());
    printf("  \033[33m%18u\033[0m | %15s \n",         miss, font[7].c_str());
    printf("---------------------+-----------------\n");
    printf("     \033[35mAccuracy\033[0m:              \033[33m%6.2lf%%\033[0m   \n", accuracy);
    printf("\n");

    if(fullcombo){
        print_fc_font("slant");
        printf("\n");
    }
    */

    printf("PERFECT:{%d}, GOOD:{%d}, MISS:{%d}, GRADE:{%s}\n", perfect, good, miss, grade_str.c_str());

    return 0;
}
