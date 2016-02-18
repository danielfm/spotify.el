;; spotify-track-search.el --- Spotify.el track search major mode

;; Copyright (C) 2014 Daniel Fernandes Martins

;; Code:

(require 'spotify-api)

(defvar spotify-track-search-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map (kbd "RET")   'spotify-track-select)
    (define-key map (kbd "M-RET") 'spotify-track-select-album)
    (define-key map (kbd "l")     'spotify-track-load-more)
    map)
  "Local keymap for `spotify-track-search-mode' buffers.")

;; Enables the `spotify-remote-mode' the track search buffer
(add-hook 'spotify-track-search-mode-hook 'spotify-remote-mode)

(define-derived-mode spotify-track-search-mode tabulated-list-mode "Track-Search"
  "Major mode for displaying the track listing returned by a Spotify search.")

(defun spotify-track-select ()
  "Plays the track under the cursor."
  (interactive)
  (spotify-play-track (car (tabulated-list-get-id))))

(defun spotify-track-select-album ()
  "Plays the album of the track under the cursor."
  (interactive)
  (spotify-play-track (cdr (tabulated-list-get-id))))

(defun spotify-track-load-more ()
  "Loads the next page of results for the current track view."
  (interactive)
  (if (boundp 'spotify-query)
      (spotify-track-search-update (1+ spotify-current-page))
    (spotify-playlist-tracks-update (1+ spotify-current-page))))

(defun spotify-track-search-update (current-page)
  "Fetches the given page of results using the search endpoint."
  (let* ((json (spotify-api-search 'track spotify-query current-page))
         (items (spotify-get-search-track-items json)))
    (if items
        (progn
          (spotify-track-search-print items)
          (setq-local spotify-current-page current-page)
          (message "Track view updated"))
      (message "No more tracks"))))

(defun spotify-playlist-tracks-update (current-page)
  "Fetches the given page of results for the current playlist."
  (let* ((json (spotify-api-playlist-tracks spotify-playlist-user-id spotify-playlist-id current-page))
         (items (spotify-get-playlist-tracks json)))
    (if items
        (progn
          (spotify-track-search-print items)
          (setq-local spotify-current-page current-page)
          (message "Track view updated"))
      (message "No more tracks"))))

(defun spotify-track-search-set-list-format ()
  "Configures the column data for the typical track view."
  (let ((default-width (truncate (/ (- (window-width) 20) 3))))
    (setq tabulated-list-format
          (vector '("#" 3 nil :right-align t)
                  `("Track Name" ,default-width t)
                  `("Artist" ,default-width t)
                  `("Album" ,default-width t)
                  '("Popularity" 10 t)))))

(defun spotify-track-search-print (songs)
  "Appens the given songs to the current track view."
  (let (entries)
    (dolist (song songs)
      (push (list (cons (spotify-get-item-uri song)
                        (spotify-get-item-uri (spotify-get-track-album song)))
                  (vector (number-to-string (spotify-get-track-number song))
                          (spotify-get-item-name song)
                          (spotify-get-track-artist song)
                          (spotify-get-track-album-name song)
                          (spotify-popularity-bar (spotify-get-track-popularity song))))
            entries))
    (setq tabulated-list-entries (append tabulated-list-entries (nreverse entries)))
    (tabulated-list-init-header)
    (tabulated-list-print t)))

(provide 'spotify-track-search)