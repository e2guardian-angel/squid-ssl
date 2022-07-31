/*
 * category.cpp
 *
 * This is the code that does the REST API calls to guardian-angel.
 * It sends an hostname to be checked, as well as the category name (which should be the name of the acl).
 */
#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <arpa/inet.h>
#include <csignal>
#include "restclient-cpp/restclient.h"
#include "json/json.h"
#include <cstdlib>

using namespace std;
const int READ_BUFFER_SIZE = 1024;

void signalHandler( int signum ) {
  exit(signum);
}

Json::Value stringToJson(std::string arg) {
  Json::Value root;
  std::istringstream jsonStream(arg);
  jsonStream >> root;
  return root;
}


int main(int argc, char **argv) {

  signal(SIGINT, signalHandler);
  signal(SIGKILL, signalHandler);
  signal(SIGHUP, signalHandler);

  /*
   * Get guardian-angel host and port from environment variables
   */
  string host, port;
  try {
    host = std::getenv("LOOKUP_HOST");
    port = std::getenv("LOOKUP_PORT");
    stoi(port.c_str());
  } catch (std::exception e) {
    cerr << "ERROR: helper section, host and/or port are missing or invalid" << endl;
    return -1;
  }

  const string HOST_CATEGORY_POST_URL = "http://" + host + ":" + port + "/lookuphost";
  const string IP_CATEGORY_POST_URL = "http://" + host + ":" + port + "/lookupip";

  /*
   * Main logic
   */
  while(1) {
    char buffer[READ_BUFFER_SIZE];
    string category, dst;
    cin.getline(buffer, 1024, '\n');
    stringstream ss(buffer);
    ss >> category;
    ss >> dst;

    struct sockaddr_in sa;
    RestClient::Response r;
    if (inet_pton(AF_INET, dst.c_str(), &(sa.sin_addr))) {
      // dst is an IP address
      r = RestClient::post(IP_CATEGORY_POST_URL, "application/json", "{\"ip\":\"" + dst + "\",\"category\":\"" + category +"\"}");
    } else {
      // dst is a hostname
      r = RestClient::post(HOST_CATEGORY_POST_URL, "application/json", "{\"hostname\":\"" + dst + "\",\"category\":\"" + category +"\"}");
    }

    if (r.code != 200) {
      cout << "ERR" << endl;
    } else {
      Json::Value responseJson = stringToJson(r.body);
      bool match = responseJson["match"].asBool();

      if (match) {
	cout << "OK" << endl;
      } else {
	cout << "ERR" << endl;
      }
    }
  }

  return 0;
  
}
