# Baseball-Tracker

The objective of this program is the track and calculate the trajectory of a baseball pitch.

Videos were taken from two different cameras in the stadium. Each pair of frames will be similar to the following.
![example_frames](example_frames.png)

The resolution of the videos is very low, leading the balls to appear as stripes of pixels that differ from their surroundings. The frame rate also makes the ball appear twice in each frame.
![ball_close_up](ball_close_up.png)

## Step 1: Detect edges
Due to the appearance of the balls, the best way to detect edges was by taking the absolute difference between each pixel and the one directly below. This was far more effective than a horizontal line detection kernel.
![vertical_difference](vertical_difference.png)

## Step 2: Blur
A Gaussian blur was applied to the results of Step 1 (convolved with a 3x3 kernel filled with 1/7s) to give the balls a more uniform shape to allow for a template to be created.
![blurred](blurred.png)

## Step 3: Template matching
A ball template was created for each camera by averaging the pixel values of several different balls relative to the center of the ball. This template was checked over the likely locations of the ball and the inverse of the average squared differences was computed to asses the quality of the match.
![detections](detections.png)

## Step 4: Enhance prediction from trajectory
The trajectory of the ball was tracked to enhance the ball detection. The quality of match was artificially increased in the areas around the predicted locations of the ball based on its trajectory. An exaggerated image of how the match quality was increased is shown below.
![trajectory](trajectory.png)
