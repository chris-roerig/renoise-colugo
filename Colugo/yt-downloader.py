import argparse
from pydub import AudioSegment, effects
from yt_dlp import YoutubeDL
import glob
import os
import random
import subprocess
import wave
import time
import sys

BATCH_SIZE = 32
MAX_SEARCH_RESULTS = 10
RUNTIME = str(int(time.time()))
WORD_LIST = 'words.txt'

# These will be set in the main function based on command line argument
DOWNLOAD_DIR = ''
LOOP_OUTPUT_DIR = ''
ONESHOT_OUTPUT_DIR = ''


def check_for_cancel():
    if os.path.exists("cancel.flag"):
        print("Cancellation requested.")
        os.remove("cancel.flag")  # Remove the flag file
        sys.exit()

def read_lines(file):
    return open(file).read().splitlines()


class download_range_func:
    def __init__(self):
        pass

    def __call__(self, info_dict, ydl):
        timestamp = self.make_timestamp(info_dict)
        yield {
            'start_time': timestamp,
            'end_time': timestamp,
        }

    @staticmethod
    def make_timestamp(info):
        duration = info['duration']
        print(duration)
        if duration is None:
            return 0
        return duration/2


def make_random_search_phrase(word_list):
    words = random.sample(word_list, 2)
    phrase = ' '.join(words)
    print('Search phrase: "{}"'.format(phrase))
    return phrase


def xmake_download_options():
    return {
        'format': 'bestaudio/best',
        'paths': {'home': DOWNLOAD_DIR},
        'outtmpl': {'default': '%(id)s.%(ext)s'},
        'download_ranges': download_range_func(),
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'wav',
        }]
    }

def make_download_options():
    return {
        'format': 'bestaudio/best',
        'paths': {'home': DOWNLOAD_DIR},
        'outtmpl': {'default': '%(title)s-%(id)s.%(ext)s'},  # Include title in the filename
        'download_ranges': download_range_func(),
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'wav',
        }]
    }

def make_oneshot(sound, output_filepath, sample_length):
    final_length = min(sample_length, len(sound))
    quarter = int(final_length/4)
    sound = sound[:final_length]
    sound = sound.fade_out(duration=quarter)
    sound = effects.normalize(sound)
    sound.export(output_filepath, format="wav")


def make_loop(sound, output_filepath, sample_length):
    final_length = min(sample_length, len(sound))
    half = int(final_length/2)
    fade_length = int(final_length/4)
    beg = sound[:half]
    end = sound[half:]
    end = end[:fade_length]
    beg = beg.fade_in(duration=fade_length)
    end = end.fade_out(duration=fade_length)
    sound = beg.overlay(end)  
    sound = effects.normalize(sound)
    sound.export(output_filepath, format="wav")


def process_file(filepath, sample_length):
    try:
        # Extract the title and id from the filename
        title_id = os.path.basename(filepath).split('.wav')[0]
        title, video_id = title_id.rsplit('-', 1)

        # Shorten the title to a desired length (e.g., first 10 characters)
        short_title = title[:10].replace(" ", "_").replace("/", "_")

        # Generate output file paths with the short title
        output_filepath_oneshot = os.path.join(ONESHOT_OUTPUT_DIR, 'oneshot_' + RUNTIME + '_' + short_title + '_' + video_id + '.wav')
        output_filepath_loop = os.path.join(LOOP_OUTPUT_DIR, 'loop_' + RUNTIME + '_' + short_title + '_' + video_id + '.wav')

        sound = AudioSegment.from_file(filepath, "wav")
        if len(sound) > 500:
            if not os.path.exists(output_filepath_oneshot):
                make_oneshot(sound, output_filepath_oneshot, sample_length)
            if not os.path.exists(output_filepath_loop):
                make_loop(sound, output_filepath_loop, sample_length)
        os.remove(filepath)
    except Exception as err:
        print("Failed to process '{}' ({})".format(filepath, err))

def setup():
    if not os.path.exists(LOOP_OUTPUT_DIR):
        os.makedirs(LOOP_OUTPUT_DIR)
    if not os.path.exists(ONESHOT_OUTPUT_DIR):
        os.makedirs(ONESHOT_OUTPUT_DIR)


def main():
    parser = argparse.ArgumentParser(description='Process some audio files.')
    parser.add_argument('output_dir', type=str, help='Path to the output directory')
    parser.add_argument('--num_videos', type=int, default=32, help='Number of videos to process')
    parser.add_argument('--sample_length', type=int, default=2000, help='Length of the sample in milliseconds')
    args = parser.parse_args()

    global DOWNLOAD_DIR, LOOP_OUTPUT_DIR, ONESHOT_OUTPUT_DIR
    DOWNLOAD_DIR = os.path.join(args.output_dir, 'raw')
    LOOP_OUTPUT_DIR = os.path.join(args.output_dir, 'processed/loop')
    ONESHOT_OUTPUT_DIR = os.path.join(args.output_dir, 'processed/oneshot')

    if os.path.exists("cancel.flag"):
        os.remove("cancel.flag")

    try:
        setup()
        word_list = read_lines(WORD_LIST)
        for _ in range(args.num_videos):
            phrase = make_random_search_phrase(word_list)
            video_url = 'ytsearch1:"{}"'.format(phrase)
            YoutubeDL(make_download_options()).download([video_url])
            for filepath in glob.glob(os.path.join(DOWNLOAD_DIR, '*.wav')):
                check_for_cancel()
                process_file(filepath, args.sample_length)
                sys.stdout.flush()
        print("Done!")
    except Exception as err:
        print('FATAL ERROR: {}'.format(err))

if __name__ == '__main__':
    main()
    sys.stdout.flush()
