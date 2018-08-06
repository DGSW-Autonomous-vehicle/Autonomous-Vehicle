#ifndef __OBSTACLE_H__
#define __OBSTACLE_H__

#define OBS_DEBUG 0
#define OBS_RELEASE 1

#include <opencv2/opencv.hpp> 
#include <vector>
#include <cmath>

using namespace cv;

class OpenCV_OBS {
private:
	Mat image;
	Rect road;

public:
	OpenCV_OBS(){}

	void setResources(Mat img, Rect areaOfRoad);
	bool hasOBS(Size minSize, int flag);
};


void OpenCV_OBS::setResources(Mat img, Rect areaOfRoad) {
	this->image = img;
	this->road = areaOfRoad;
}

bool OpenCV_OBS::hasOBS(Size minSize, int flag) {
	Mat roi = image(road);
	Mat hsv_roi;
	cvtColor(roi, hsv_roi, COLOR_BGR2HSV);
	int col_count = 0;
	int row_count = 0;

	for (int i = 0; i < roi.cols; i++) {
		for (int j = 0; j < roi.rows; j++) {
			Vec3b pixel = hsv_roi.at<Vec3b>(Point(i, j));
			if (pixel[3] <= 200) {
				col_count++;
			}
			else {
				if (hsv_roi.at<Vec3b>(Point(i + 1, j))[3] <= 200 || hsv_roi.at<Vec3b>(Point(i + 2, j))[3] <= 200) {
					col_count++;
				}
			}
		}
		if (col_count >= minSize.width) {
			row_count++;
		}
		else {
			col_count = 0;
		}
	}

	if (flag == OBS_DEBUG) {
		imshow("OBS_DEBUG", roi);
	}

	if (row_count >= minSize.height)
		return true;

	return false;
}

#endif
