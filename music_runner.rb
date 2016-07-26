def play_bell(n)
  puts "PLAYING BELL"
  n.times do
    system("AUDIODEV=hw:0 play /home/pi/Music/samples/bell.wav gain -20 > /dev/null")
    sleep 3
  end
end

def fourtwenty
  system("mplayer /home/pi/Music/samples/420.mp3 > /dev/null")
  sleep 10
end

def check_for_time
  minutes = Time.now.strftime('%M').to_i
  hours = Time.now.strftime('%H').to_i % 12
  if minutes == 0
    return if @time_spoken
    play_bell(hours)
    @time_spoken = true
  elsif hours == 4 && minutes == 20
    fourtwenty
  end
  @time_spoken = false if minutes > 0
end

def check_memory
  space_left = `df -m /`.split(/\b/)[24].to_i
  while space_left < 200 && file = Dir.glob('/home/pi/Music/wavs/*.wav').sample
    system("rm #{file}")
    puts "FILE REMOVED - #{file}"
    space_left = `df -m /`.split(/\b/)[24].to_i
  end
end

def play_random_mp3
  return if system('ps aux | grep -v grep | grep mplayer | grep -v \<defunct\> > /dev/null')
  file = Dir.glob("/home/pi/Music/*.mp3").sample
  puts "MP3 playing is #{file}"
  fork{ system("mplayer #{file} > /dev/null") }
end

def record_sound_snippet
  return if system('ps ax | grep -v grep | grep rec | grep -v zenity | grep -v \<defunct\> > /dev/null')
  random = rand(10000)
  puts "RECORDING SNIPPET #{random}"
  fork{ system("AUDIODEV=hw:1 rec -c 1 /home/pi/Music/wavs/#{random}.wav trim 0 10 gain 5 > /dev/null")}
end

def play_random_snippet
  return if system('ps ax | grep -v grep | grep -v mplayer | grep play | grep -v \<defunct\> > /dev/null')
  wav = Dir.glob("/home/pi/Music/wavs/*.wav").sample
  wav = Dir.glob("/home/pi/Music/wavs/*.wav").sort_by { |f| File.mtime(f) }[-1] if rand(10) > 6
  puts "PLAYING wav #{wav}"
  size1 = File.size(wav) rescue 0
  sleep(0.1)
  size2 = File.size(wav) rescue 0
  if wav && size1 == size2
    fork{ system("AUDIODEV=hw:0 play #{wav} noisered /home/pi/Music/noise.prof 0.28 gain 2 reverb 0.8 delay 0.18 > /dev/null") }
  end
end

loop do
  check_memory
  play_random_mp3
  record_sound_snippet
  play_random_snippet
  sleep 0.5
  check_for_time
end
