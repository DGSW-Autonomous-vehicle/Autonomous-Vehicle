#include "TL.hpp"

OpenCV_TL::OpenCV_TL() {

}

int OpenCV_TL::getLightInfo(int flag) {
	cvtColor(image, gray, COLOR_BGR2GRAY);
	cvtColor(image, hsv, COLOR_BGR2HSV);
	HoughCircles(gray, circles, HOUGH_GRADIENT, 2, 5, 100, 200, 20, 160);
	if (flag == LIGHT_NO_CONDITION) {
		TL = circles;
	}
	if (flag == LIGHT_HORIZONTAL) {
		for (int i = 0; i < circles.size(); i++) {
			for (int j = 0; j < circles.size(); j++) {
				if (i == j)
					continue;
				if (abs(circles[i][0] - circles[j][0]) <= 3) {
					TL.push_back(circles[i]);
				}
			}
		}
	}
	if (flag == LIGHT_VERTICAL) {
		for (int i = 0; i < circles.size(); i++) {
			for (int j = 0; j < circles.size(); j++) {
				if (i == j)
					continue;
				if (abs(circles[i][1] - circles[j][1]) <= 3) {
					TL.push_back(circles[i]);
				}
			}
		}
	}
	if (TL.size >= 0) {
		for (int i = 0; i < TL.size(); i++) {
			circle(image, Point(TL[i][0], TL[i][1]), TL[i][2], Scalar(0, 0, 255), 2);
			int Color = getPixelInfo(Point(TL[i][0], TL[i][1]));
			switch (Color) {
			case RED:
				return -1;
				break;
			case GREEN:
				return 0;
				break;
			case BLACK:
				break;
			}
		}
	}
	else {
		cout << "No Circle" << endl;
	}
}

int OpenCV_TL::getPixelInfo(Point pt) {
	Vec3b pixel = hsv.at<Vec3b>(pt);

	if (pixel[2] < 85) {
		return BLACK;
	}
	else if (pixel[0] <= 15) {
		return RED;
	}
	else if (pixel[0] <= 75 && pixel[0] >= 45) {
		return GREEN;
	}
	else if (pixel[0] >= 165) {
		return RED;
	}
	else {
		return OTHERS;
	}
	return OTHERS;
}

void OpenCV_TL::setImage(Mat img) {
	this->image = img;
}