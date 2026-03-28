import Testing
@testable import YOLO_DL

struct YOLO_DL_Tests {
    
    @Test func testDurationPicker() {
        #expect(DurationFormatter.format(minutes: 1) == "1 min")
        #expect(DurationFormatter.format(minutes: 60) == "1 h")
        #expect(DurationFormatter.format(minutes: 61) == "1 h 1 min")
        #expect(DurationFormatter.format(minutes: 0) == "No limit")
        #expect(DurationFormatter.format(minutes: -5) == "No limit")
    }
    
    @Test func testErrorParser() {
        let parser = ErrorParser()
        #expect(parser.parseErrors("Unsupported URL") == "The URL doesn't appear to be from Yle Areena or another supported Yle service. Check the URL and try again.")
        #expect(parser.parseErrors("No streams found") == "yle-dl failed to find a stream in the provided URL. Try again or with a different URL.")
        #expect(parser.parseErrors("And now for something completely different") == nil)
        #expect(parser.parseErrors("") == nil)
        #expect(parser.parseErrors("Unsupported URL and No streams found") == "The URL doesn't appear to be from Yle Areena or another supported Yle service. Check the URL and try again.")
    }
    
    @Test func testEpisodeMetadata() {
        let episode = EpisodeMetadata(
            durationSeconds: 1800,
            title: "Some Title S01E05",
            episodeTitle: "Some Series: Some Title",
            publishedTimestamp: "2026-03-28T12:00:00Z",
            flavors: []
            )
        let result = episode.predictedFileStem(for: .seriesDateTitle)

        #expect(result == "Some Series: S01E05 - Some Title")
    }

    @Test func testContentType() {
        let vod = EpisodeMetadata(
            durationSeconds: 1800,
            title: "VOD Episode",
            episodeTitle: "Series: VOD Episode",
            publishedTimestamp: "2026-03-28T12:00:00Z",
            flavors: [.init(url: "https://cdn.example.com/video/stream.m3u8")]
        )
        #expect(vod.contentType == .vod)

        let liveStream = EpisodeMetadata(
            durationSeconds: 30000,
            title: "Live Stream",
            episodeTitle: "Series: Live Stream",
            publishedTimestamp: "2026-03-28T12:00:00Z",
            flavors: [.init(url: "https://cdn.example.com/live/stream.m3u8")]
        )
        #expect(liveStream.contentType == .liveStream)

        let tvChannel = EpisodeMetadata(
            durationSeconds: nil,
            title: "TV Channel",
            episodeTitle: "TV Channel",
            publishedTimestamp: "2026-03-28T12:00:00Z",
            flavors: [.init(url: "https://cdn.example.com/live/channel.m3u8")]
        )
        #expect(tvChannel.contentType == .tvChannel)
    }

    @Test @MainActor func testParseStderr() {
        let dm = DownloadManager(logger: LogManager())
        dm.totalDuration = 1800

        let line = "size= 51200KiB time=00:15:30.00 bitrate= 450.0kbits/s speed=25.3x"
        let fields = dm.parseStderr(line)

        #expect(fields.progress != nil)
        #expect(fields.fileSize == "52.4 MB")
        #expect(fields.speed == 25.3)

        let naLine = "size= 1024KiB time=N/A bitrate=N/A speed=N/A"
        let naFields = dm.parseStderr(naLine)
        #expect(naFields.progress == nil)
    }
}
