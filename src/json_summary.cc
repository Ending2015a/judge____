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
    Sheet(bool detail=false) : isOpened(false), detail(detail){}
    Sheet(std::string name, bool detail=false) : isOpened(false), detail(detail){
        open(name);
    }

    ~Sheet(){ close(); }

    void open(std::string name){
        this->name = name;
        fout.open(name);
        std::cout << "Open: " << name << std::endl;
        isOpened = true;
    }

    void close(){
        flush();
        fout.close();
        isOpened = false;
    }

    void flush(){

        std::vector<std::string> row(title.size());

        for(auto it=title.begin(); it != title.end(); ++it){
            row[it->second] = it->first;
        }

        for(int i=0;i<row.size();++i){
            if(i != 0) fout << ", ";
            fout << row[i];
        }
        fout << std::endl;

        for(int i=0;i<buf.size();++i){
            for(int j=0;j<buf[i].size();++j){
                if(j != 0)fout << ", ";
                fout << buf[i][j];
            }
            fout << std::endl;
        }
    }

    virtual void write(){};
    virtual void createTitles(){}

    std::vector<std::string> getRow(int idx){
        return buf[idx];
    }

    std::vector<std::string> getCol(int idx){
        std::vector<std::string> c;
        for(int i=0;i<buf.size(); ++i){
            c.push_back(buf[i][idx]);
        }
        return c;
    }

    std::vector<std::string> &operator[](int idx){
        return buf[idx];
    }

protected:
    std::string name;
    std::map<std::string, int> title;
    std::ofstream fout;
    bool isOpened;
    bool detail;
    std::vector<std::vector<std::string>> buf;
};



class HW2Sheet : public Sheet{
public:
    HW2Sheet(std::string name, bool detail=false) : Sheet(name, detail) {}

    std::string getCaseTitle(int Case, int Round, std::string term){
        char t[30] = {};
        sprintf(t, "c%d_r%d_", Case, Round);
        return std::string(t) + term;
    }

    std::string getTitle(int Case, std::string term){
        char t[30]={};
        sprintf(t, "c%d_", Case);
        return std::string(t) + term;
    }

    std::string minTime(std::string &A, std::string &B){
        if(A == "inf")return B;
        if(B == "inf")return A;
        return atof(A.c_str()) < atof(B.c_str()) ? A:B;
    }
    

    virtual void write(tao::json::value &data, int max_case, int max_round){
        std::vector<std::string> row(title.size());
        row[title["User"]] = data["user"].get_string();
        tao::json::value &v = data["data"];

        std::vector<std::string> bestTime(max_case, "inf");

        for(int i=0;i<v.get_array().size(); ++i){
            int Case = v[i]["case"].get_unsigned();
            int Round = v[i]["round"].get_unsigned();

            if(detail){
                row[ title[getCaseTitle(Case, Round, "Perfect")] ] = v[i]["perfect"].get_string();
                row[ title[getCaseTitle(Case, Round, "Good")] ] = v[i]["good"].get_string();
                row[ title[getCaseTitle(Case, Round, "Miss")] ] = v[i]["miss"].get_string();
            }

            row[ title[getCaseTitle(Case, Round, "Grade")] ] = v[i]["grade"].get_string();
            row[ title[getCaseTitle(Case, Round, "Time")] ] = v[i]["time"].get_string();
            row[ title[getCaseTitle(Case, Round, "Err")] ] = std::to_string(v[i]["error"].get_unsigned());
            row[ title[getCaseTitle(Case, Round, "ErrMsg")]] = v[i]["error_msg"].get_string();
            
            bestTime[Case] = minTime(bestTime[Case], v[i]["time"].get_string());
        }

        for(int i=0;i<max_case;++i){
            row[ title[getTitle(i, "BestTime")] ] = bestTime[i];
        }

        row[title["Remark"]] = data["remark"].get_string();
        
        buf.push_back(row);
    }

    virtual void createTitles(int max_case, int max_round){
        int column = 0;
        title.clear();
        title["User"] = column++;
        for(int i=0;i<max_round;++i){
            for(int j=0;j<max_case;++j){
                if(detail){
                    title[getCaseTitle(j, i, "Perfect")] = column++;
                    title[getCaseTitle(j, i, "Good")] = column++;
                    title[getCaseTitle(j, i, "Miss")] = column++;
                }
                title[getCaseTitle(j, i, "Grade")] = column++;
                title[getCaseTitle(j, i, "Time")] = column++;
                title[getCaseTitle(j, i, "Err")] = column++;
                title[getCaseTitle(j, i, "ErrMsg")] = column++;
            }
        }

        for(int j=0;j<max_case;++j){
            title[getTitle(j, "BestTime")] = column++;
        }

        title["Remark"] = column++;
    }
private:
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

        std::cout << "user: " << v["user"] << std::endl;
        std::cout << "remark: " << v["remark"] << std::endl;
        std::cout << "data: " << v["data"].get_array().size() << std::endl;

        for(int j=0;j<v["data"].get_array().size();++j){
            std::cout << "\tarray " << j << " case: " << v["data"][j]["case"] << std::endl;
            std::cout << "\tarray " << j << " round: " << v["data"][j]["round"] << std::endl;
            std::cout << "\tarray " << j << " perfect: " << v["data"][j]["perfect"] << std::endl;
            std::cout << "\tarray " << j << " good: " << v["data"][j]["good"] << std::endl;
            std::cout << "\tarray " << j << " miss: " << v["data"][j]["miss"] << std::endl;
            std::cout << "\tarray " << j << " grade: " << v["data"][j]["grade"] << std::endl;
            std::cout << "\tarray " << j << " time: " << v["data"][j]["time"] << std::endl;
            std::cout << "\tarray " << j << " error: " << v["data"][j]["error"] << std::endl;
            std::cout << "\tarray " << j << " error_msg: " << v["data"][j]["error_msg"] << std::endl;

            max_case = max(max_case, v["data"][j]["case"].get_unsigned());
            max_round = max(max_round, v["data"][j]["round"].get_unsigned());
        }
    }

    max_case ++;
    max_round++;

    HW2Sheet ssheet("./score.csv");
    HW2Sheet csheet("./score_detail.csv", true);  //verbose

    ssheet.createTitles(max_case, max_round);
    csheet.createTitles(max_case, max_round);

    for(int i=0;i<argc-1;++i){
        ssheet.write(user_data[i], max_case, max_round);
        csheet.write(user_data[i], max_case, max_round);
    }

    ssheet.close();
    csheet.close();

    return 0;
}
