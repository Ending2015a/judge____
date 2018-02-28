#include <iostream>
#include <fstream>
#include <vector>
#include <map>
#include <string>

#include <cstdio>
#include <cstdlib>

#include <tao/json.hpp>

#define max(x, y) ((x)>(y) ? (x):(y))



class Sheet{
public:
    Sheet(){}
    Sheet(std::string name){
        open(name);
    }

    void open(std::string name){
        this->name=name;
        fout.open(name);
    }

    void write(tao::json::value &v){
        std::vector<std::string> row(title.size());
        for(int i=0;i<v.get_array().size(); ++i){
            if(i==0){
                row[0] = v[0]["user"].get_string();
            }

            int Case = v[i]["case"].get_unsigned();
            int Round = v[i]["round"].get_unsigned();

            row[ title[getCaseTitle(Case, Round, "Grade")] ] = v[i]["grade"].get_string();
            row[ title[getCaseTitle(Case, Round, "Time")] ] = v[i]["time"].get_string();
            row[ title[getCaseTitle(Case, Round, "Error")] ] = v[i]["error_msg"].get_string();
        }

        for(int i=0;i<row.size();++i){
            if(i != 0)fout << ", ";
            fout << row[i];
        }

        fout << std::endl;
    }

    std::string getCaseTitle(int Case, int Round, std::string postfix){
        char t[30] = {};
        sprintf(t, "Case%02d_%02d_", Case, Round);
        return std::string(t) + postfix;
    }

    void createTitles(int max_case, int max_round){
        int column_index = 0;
        title.clear();
        title["User"] = column_index++;
        for(int i=0;i<max_round;++i){
            for(int j=0;j<max_case;++j){
                title[getCaseTitle(j, i, "Grade")] = column_index++;
                title[getCaseTitle(j, i, "Time")] = column_index++;
                title[getCaseTitle(j, i, "Error")] = column_index++;
            }
        }
    }

    void writeTitles(){
        std::vector<std::string> row(title.size());

        for(auto it=title.begin(); it != title.end(); ++it){
            row[it->second] = it->first;
        }

        for(int i=0;i<row.size();++i){
            if(i != 0)fout << ", ";
            fout << row[i];
        }

        fout << std::endl;
    }

    void close(){
        fout.close();
    }

private:
    std::string name;
    std::map<std::string, int> title;
    std::ofstream fout;
};

// ./summary $result_list
int main(int argc, char **argv){
    
    int user_count = argc-1;

    tao::json::value user_data[user_count];

    int max_case = 0;
    int max_round = 0;

    for(int i=1;i<argc;++i){
        tao::json::value &v = user_data[i-1];
        v = tao::json::parse_file(argv[i]);
        std::cout << "is array: " << v.is_array() << std::endl;
        std::cout << "array size: " << v.get_array().size() << std::endl;

        for(int j=0;j<v.get_array().size();++j){
            std::cout << "array " << j << " user: " << v[j]["user"] << std::endl;
            std::cout << "array " << j << " case: " << v[j]["case"] << std::endl;
            std::cout << "array " << j << " round: " << v[j]["round"] << std::endl;
            std::cout << "array " << j << " grade: " << v[j]["grade"] << std::endl;
            std::cout << "array " << j << " time: " << v[j]["time"] << std::endl;
            std::cout << "array " << j << " error_msg: " << v[j]["error_msg"] << std::endl;

            max_case = max(max_case, v[j]["case"].get_unsigned());
            max_round = max(max_round, v[j]["round"].get_unsigned());
        }
    }

    max_case ++;
    max_round++;

    Sheet sheet("./result.csv");

    sheet.createTitles(max_case, max_round);
    
    sheet.writeTitles();

    for(int i=0;i<argc-1;++i){
        sheet.write(user_data[i]);
    }

    sheet.close();

    return 0;
}
