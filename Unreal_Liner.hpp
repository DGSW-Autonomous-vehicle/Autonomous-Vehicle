#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>
//#include "obstacle.hpp"
//#include "TL.hpp"


#define M_PI 3.14159265358979323846

using namespace cv;
using namespace std;

class Liner {
private:
	string file = "image/0.jpg";
	Mat HSV;
	int roi_height = 380;
	Size roisize = Size(64, 64);

	Rect Roi1 = Rect(Point(100, roi_height), roisize);
	Rect Roi2 = Rect(Point(640 - 100 - roisize.width, roi_height), roisize);

	Rect Roi3 = Rect(Point(100 - roisize.width, roi_height), roisize);
	Rect Roi4 = Rect(Point(640 - 100, roi_height), roisize);

	int D = 30;
	int C = 320;
	int golowX = C - D;
	int gohighX = C + D;
	
  //  OpenCV_OBS obs;

	//OpenCV_TL traffic;

	float radtodegree(float th);

	void drawlines(Mat src, vector<Vec2f> lines, Rect roi);

	vector<Vec2f> getlines(Mat src, int lowT, int highT, Rect roi_rect, bool mode = 0);

	bool IntersectPoint(int *x, int *y, int x1, int x2, int x3, int x4, int y1, int y2, int y3, int y4);

	vector<Point> getCrossPoint(Mat src, vector<Vec2f> line_1, vector<Vec2f> line_2, bool mode);

	Point AvgPoint(vector<Point> points);

	float AvgLineAngle(vector<Vec2f> line);

	void set_flag(Point p);

	int flag_center(int Tx);

	int getCenterline(Mat src);

	//int flag_ass(Mat m);

public:
	Mat img;
	void startLiner();
	bool modes = 0;
	int flag = -1;
};

/*
# -1 = not detected
#  0 = go throught
#  1 = go right
#  2 = go left
#  3 = go and right
#  4 = go and left
*/

/*
150 ~ 160 && 330 ~ 340
20 ~  30 && 200 ~ 210
*/

float Liner::radtodegree(float th) {
	return  th / M_PI * 180;
}

void Liner::drawlines(Mat src, vector<Vec2f> lines, Rect roi) {
	for (auto it = lines.begin(); it != lines.end(); it++) {
		float rho = (*it)[0];
		float th = (*it)[1];

		double x0 = cos(th) * rho;
		double y0 = sin(th) * rho;

		int x1 = (int)x0 + 1000 * (-sin(th)) + roi.x;
		int x2 = (int)x0 - 1000 * (-sin(th)) + roi.x;
		int y1 = (int)y0 + 1000 * (cos(th)) + roi.y;
		int y2 = (int)y0 - 1000 * (cos(th)) + roi.y;

		line(src, Point(x1, y1), Point(x2, y2), Scalar(0, 0, 255), 2);
	}
	cout << "lines counting" << lines.size() << " in " << roi.x << endl;
}

vector<Vec2f> Liner::getlines(Mat src, int lowT, int highT, Rect roi_rect, bool mode) {
	vector<Vec2f> lines;
	Mat roi = src(roi_rect);
	//cvtColor(roi,roi,COLOR_BGR2GRAY);
	Mat edgs;
	Canny(roi, edgs, lowT, highT);
	HoughLines(edgs, lines, 1, M_PI / 180, 41);
	if (mode == 1) {
		if (lines.size() != 0) {
			drawlines(src, lines, roi_rect);
		}
		imshow(to_string(roi_rect.x), edgs);
	}
	return lines;
}

bool Liner::IntersectPoint(int *x, int *y, int x1, int x2, int x3, int x4, int y1, int y2, int y3, int y4) {
	int under = (y4 - y3)*(x2 - x1) - (x4 - x3)*(y2 - y1);

	if (under == 0) {
		//cout << "error 1";
		return false;
	}

	int tt = (x4 - x3) * (y1 - y3) - (y4 - y3)*(x1 - x3);
	int ss = (x2 - x1) * (y1 - y3) - (y2 - y1)*(x1 - x3);

	float t = tt / under;
	float s = ss / under;
	/*
	if (t < 0 || t == 1 || s < 0 || s == 1) {
	if(s<0)
	cout << "t";
	return false;
	}
	*/
	if (tt == 0 && ss == 0) {
		//cout << "error 3";
		return false;
	}

	*x = x1 + t * (x2 - x1);
	*y = y1 + t * (y2 - y1);

	return true;
}

vector<Point> Liner::getCrossPoint(Mat src, vector<Vec2f> line_1, vector<Vec2f> line_2, bool mode) {

	vector<Point> points;
	for (auto it = line_1.begin(); it != line_1.end(); it++) {
		float rho = (*it)[0];
		float th = (*it)[1];

		double x0 = cos(th) * rho;
		double y0 = sin(th) * rho;

		int x1 = (int)x0 + 10 * (-sin(th)) + Roi1.x;
		int x2 = (int)x0 - 10 * (-sin(th)) + Roi1.x;
		int y1 = (int)y0 + 10 * (cos(th)) + Roi1.y;
		int y2 = (int)y0 - 10 * (cos(th)) + Roi1.y;

		for (auto it2 = line_2.begin(); it2 != line_2.end(); it2++) {
			float rho2 = (*it2)[0];
			float th2 = (*it2)[1];

			double x02 = cos(th2) * rho2;
			double y02 = sin(th2) * rho2;

			int x12 = (int)x02 + 10 * (-sin(th2)) + Roi2.x;
			int x22 = (int)x02 - 10 * (-sin(th2)) + Roi2.x;
			int y12 = (int)y02 + 10 * (cos(th2)) + Roi2.y;
			int y22 = (int)y02 - 10 * (cos(th2)) + Roi2.y;

			int x, y;

			if (IntersectPoint(&x, &y, x1, x2, x12, x22, y1, y2, y12, y22)) {
				points.push_back(Point(x, y));
				if (mode == 1)
					circle(src, Point(x, y), 3, Scalar(255, 0, 255), 2);
			}
			else {
				//cout << "error" << endl;
			}
		}
	}
	return points;
}

Point Liner::AvgPoint(vector<Point> points) {
	int Xsum = 0;
	int Ysum = 0;
	for (int i = 0; i < points.size(); i++) {
		Xsum += points[i].x;
		Ysum += points[i].y;
	}
	Point pt = Point(Xsum / points.size(), Ysum / points.size());
	return pt;
}

float Liner::AvgLineAngle(vector<Vec2f> line) {
	float thsum = 0;
	for (auto it = line.begin(); it != line.end(); it++) {
		float th = (*it)[1];
		thsum += th / M_PI * 180;
	}
	return (thsum / line.size());
}

int Liner::getCenterline(Mat src) {
	int H = roi_height + roisize.height;
	Rect roi_h = Rect(Point(0, H), Point(640, H + 1));
	Mat roi = src(roi_h);
	Mat hsvroi;
	cvtColor(roi, hsvroi, COLOR_BGR2HSV);

	int cnt = 0;
	int Rx = 0, Lx = 0;

	for (int i = 320; i < 640; i++) {
		if (hsvroi.at<Vec3b>(0, i)[1] < 30 && hsvroi.at<Vec3b>(0, i)[2] > 190) {
			cnt++;
		}
		if (cnt > 5) {
			Rx = i;
			break;
		}
	}
	cnt = 0;
	for (int i = 320; i >= 0; i--) {
		if (hsvroi.at<Vec3b>(0, i)[1] < 30 && hsvroi.at<Vec3b>(0, i)[2] > 190) {
			cnt++;
		}
		if (cnt > 5) {
			Lx = i;
			break;
		}
	}

	return (Rx + Lx) / 2;
}

void Liner::set_flag(Point p) {
	if (p.x == -1) {
		flag = -1;
		return;
	}
	else {
		if (p.x >= golowX && p.x <= gohighX) {
			flag = 0;
			return;
		}
		else
			if (p.x < golowX) {
				flag = 2;
				return;
			}
			else
				if (p.x > gohighX) {
					flag = 1;
					return;
				}
	}
	flag = -1;
	return;
}

int Liner::flag_center(int Tx) {
	if (Tx == 0) {
		flag = 0;
		return 0;
	}
	else {
		if (Tx >= golowX - 10 && Tx <= gohighX + 10) {
			flag = 0;
			return 0;
		}
		else
			if (Tx < golowX - 10) {
				flag = 4;
				return 1;
			}
			else
				if (Tx > gohighX + 10) {
					flag = 3;
					return 1;
				}
	}
	return 0;
}
/*
int Liner::flag_ass(Mat m) {
rectangle(m,Rect(Point(),Point()), Scalar(0, 0, 0));
imshow("image", img);
return 0;
}
*/
void Liner::startLiner() {
	vector<Point> points;
	vector<Vec2f> line_1;
	vector<Vec2f> line_2;
	vector<Vec2f> line_3;
	vector<Vec2f> line_4;
	Point Avgpt;
	Mat img;
	VideoCapture cap(0);

	float angle;


	while (1) {
		int TX = 0;
		angle = -1;
		Avgpt = Point(-1, -1);
		cap >> img;
		flip(img, img, -1);
		//img = imread(file);

		TX = getCenterline(img);
 	//	obs.setResources(img, Rect(C - 60, 240, C  + 60, 400));
//		traffic.setImage(img);

//		int lightflag = traffic.getLightInfo(LIGHT_VERTICAL);
		line_1 = getlines(img, 100, 200, Roi1, modes);
		line_2 = getlines(img, 100, 200, Roi2, modes);

		if (line_1.size() != 0 && line_2.size() != 0) {//1,2ï¿½ï¿½ ï¿½ï¿½ï¿?ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ ï¿½ï¿½ï¿½ï¿½
			if (modes)
				cout << "1 and 2" << endl;
			points = getCrossPoint(img, line_1, line_2, modes);
			if (points.size() != 0) {
				Avgpt = AvgPoint(points);
				if (modes)
					circle(img, Avgpt, 5, Scalar(255, 255, 0), 2);
			}
		}
		else {
			if (line_1.size() == 0 && line_2.size() == 0) {//ï¿½Ù¾È°ï¿½ï¿½ï¿½
				if (modes)
					cout << "not 1 and 2" << endl;
				line_3 = getlines(img, 100, 200, Roi3, modes);
				line_4 = getlines(img, 100, 200, Roi4, modes);

				if (line_3.size() != 0 && line_4.size() != 0) {
					points = getCrossPoint(img, line_3, line_4, modes);
					if (points.size() != 0) {
						Avgpt = AvgPoint(points);
						if (modes)
							circle(img, Avgpt, 5, Scalar(255, 0, 255), 2);
					}
				}
				else if (line_3.size() != 0) {//line3 is not null
					angle = AvgLineAngle(line_3);
				}
				else if (line_4.size() != 0) {//line4 is not null
					angle = AvgLineAngle(line_4);
				}
				else { // all null
					   //stop
					Avgpt.x = -1;
					Avgpt.y = -1;
				}

				if ((angle > 150 && angle < 160) || (angle > 330 && angle < 340)) {
					Avgpt.x = 320;
					Avgpt.y = 300;
				}
				else if ((angle > 20 && angle < 30) || (angle > 200 && angle < 210)) {
					Avgpt.x = 320;
					Avgpt.y = 300;
				}
				else if ((angle > 1 && angle < 89) || (angle > 181 && angle < 269)) {//ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
					Avgpt.x = 600;
					Avgpt.y = 300;
				}
				else if ((angle > 91 && angle < 179) || (angle > 271 && angle < 359)) {//ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
					Avgpt.x = 40;
					Avgpt.y = 300;
				}
				else {
					Avgpt.x = -1;
					Avgpt.y = -1;
				}
			}
			else {//1,2ï¿½ï¿½ï¿½Ï³ï¿½ ï¿½ï¿½ï¿½ï¿½
				if (modes)
					cout << "1 or 2" << endl;

				if (line_1.size() != 0) { //1ï¿½ï¿½ï¿½ï¿½ ï¿½ï¿½ï¿½ï¿½
					angle = AvgLineAngle(line_1);
				}
				else if (line_2.size() != 0) {//2ï¿½ï¿½ï¿½ï¿½ ï¿½ï¿½ï¿½ï¿½
					angle = AvgLineAngle(line_2);
				}

				if ((angle > 150 && angle < 160) || (angle > 330 && angle < 340)) {
					Avgpt.x = 320;
					Avgpt.y = 300;
				}
				else if ((angle > 20 && angle < 30) || (angle > 200 && angle < 210)) {
					Avgpt.x = 320;
					Avgpt.y = 300;
				}
				else if ((angle > 1 && angle < 89) || (angle > 181 && angle < 269)) {//ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
					Avgpt.x = 600;
					Avgpt.y = 300;
				}
				else if ((angle > 91 && angle < 179) || (angle > 271 && angle < 359)) {//ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
					Avgpt.x = 40;
					Avgpt.y = 300;
				}
				else {
					Avgpt.x = -1;
					Avgpt.y = -1;
				}
			}
		}

		if (flag_center(TX)) {
			//			cout << flag << endl;
			//			imshow("aaaaaaa",img);
			waitKey(30);
		}
		else {
			set_flag(Avgpt);
		}
	//	if(obs.hasOBS(Size(10,10), OBS_RELEASE)){
	//  	    flag = -1;
    //    }
    //    else{
    //        flag = 0;
    //    }

	//	if(lightflag == -1)
    //       flag = -1;
	//	else
	//	flag = 0;
		//center;
		if (modes) {
			cout << "flag = " << flag << endl;
			line(img, Point(TX, 0), Point(TX, 480), Scalar(255, 0, 255), 1);
			line(img, Point(golowX, 0), Point(golowX, 480), Scalar(255, 255, 255), 1);
			line(img, Point(320, 0), Point(320, 480), Scalar(0, 0, 0), 1);
			line(img, Point(gohighX, 0), Point(gohighX, 480), Scalar(255, 255, 255), 1);

			rectangle(img, Roi1, Scalar(0, 0, 0));
			rectangle(img, Roi2, Scalar(0, 0, 0));
			rectangle(img, Roi3, Scalar(0, 0, 0));
			rectangle(img, Roi4, Scalar(0, 0, 0));
			imshow("image", img);
		}

		waitKey(60);
		//imshow("image", img);
		cout << "flag = " << flag << endl;
	}
}
/*
int main(){
Liner line;
line.startLiner();
waitKey(0);
return 0;
}
*/
