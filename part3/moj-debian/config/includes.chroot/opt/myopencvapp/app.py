import cv2
import numpy as np

def main():
    # Ustawienia okna na pełny ekran
    cv2.namedWindow("OpenCV GUI", cv2.WND_PROP_FULLSCREEN)
    cv2.setWindowProperty("OpenCV GUI", cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)

    # Tworzymy tło i przycisk
    img = np.zeros((600, 1000, 3), dtype=np.uint8)
    cv2.putText(img, "OpenCV GUI Demo", (250, 150), cv2.FONT_HERSHEY_SIMPLEX, 2, (255,255,255), 3)
    # Rysujemy przycisk Exit GUI
    button_color = (40, 180, 40)
    button_pos = (400, 400, 600, 500)  # x1, y1, x2, y2
    cv2.rectangle(img, (button_pos[0], button_pos[1]), (button_pos[2], button_pos[3]), button_color, -1)
    cv2.putText(img, "Exit GUI", (button_pos[0]+30, button_pos[1]+60), cv2.FONT_HERSHEY_SIMPLEX, 2, (255,255,255), 3)

    while True:
        cv2.imshow("OpenCV GUI", img)
        key = cv2.waitKey(1) & 0xFF
        if key == 27:  # ESC
            break

        # Obsługa kliknięcia myszą
        def on_mouse(event, x, y, flags, param):
            if event == cv2.EVENT_LBUTTONDOWN:
                if button_pos[0] <= x <= button_pos[2] and button_pos[1] <= y <= button_pos[3]:
                    cv2.destroyAllWindows()
                    exit(0)
        cv2.setMouseCallback("OpenCV GUI", on_mouse)

    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
