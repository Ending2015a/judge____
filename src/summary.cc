#include <iostream>
#include <fstream>
#include <vector>

#include <cstdlib>

#include <tao/json.hpp>

// ./summary $result_list
int main(int argc, char **argv){
    
    for(int i=1;i<argc;++i){
        tao::json::value v = tao::json::parse_file(argv[i]);
        std::cout << "is array: " << v.is_array() << std::endl;
        std::cout << "array size: " << v.get_array().size() << std::endl;

        for(int j=0;j<v.get_array().size();++j){
            std::cout << "array " << j << " user: " << v[j]["user"] << std::endl;
            std::cout << "array " << j << " case: " << v[j]["case"] << std::endl;
            std::cout << "array " << j << " round: " << v[j]["round"] << std::endl;
            std::cout << "array " << j << " grade: " << v[j]["grade"] << std::endl;
            std::cout << "array " << j << " time: " << v[j]["time"] << std::endl;
            std::cout << "array " << j << " error_msg: " << v[j]["error_msg"] << std::endl;
        }
    }
    
    return 0;
}
