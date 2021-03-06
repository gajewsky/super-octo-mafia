import ApiClient from '/api_client.js';

const audioFiles = {
  night_voting: new Audio(`/night_voting.wav`),
  night_results: new Audio(`/night_results.wav`),
  mafia_open_eyes: new Audio('/mafia_open_eyes.wav')
}

function stateIdChanged(oldState, newState) {
}
function notifyNewState(appState) {
  // console.log('state id changed!', appState);
  if (appState.state.id === 'night_voting' || appState.state.id === 'night_results') {
    // console.log('in regular play');
    audioFiles[appState.state.id].play().then((e) => console.log('played:', e));
  }

  if (appState.state.id === 'night_voting') {
    // console.log('set timeout');
    setTimeout(() => {
      // console.log('in set timeout');
      audioFiles['mafia_open_eyes'].play().then((e) => console.log('delay played:', e));
    }, 15000);
  }
}
window.notifyNewState = notifyNewState;

function init() {
  console.log('init');

  let app = new Vue({
    el: '#app',
    data: {
      appState: {
        version: 0,
        state: {
          id: 'new_town_form',
        }
      },
      playerName: null,
    },

    async mounted() {
      if (localStorage.playerName) {
        this.playerName = localStorage.playerName;
      }

      let pathParts = window.location.pathname.split('/');
      if (pathParts.length === 3 && pathParts[1] === 'towns') {
        this.appState.slug = pathParts[2];
        await this.loadState();
        this.startPolling();
      }
    },

    computed: {
      killedPlayerCharacter() {
        if (this.appState.state.id === 'day_results' || this.appState.state.id === 'night_results') {
          return this.appState.players[this.appState.state.killed_player].character;
        }

        return false;
      },

      currentPlayer() {
        if (this.appState && this.appState.players) {
          return this.appState.players[this.playerName];
        }

        return false;
      },

      isCurrentPlayerMafia() {
        if (this.appState && this.appState.players && this.appState.players[this.playerName]) {
          return this.appState.players[this.playerName].character === 'mafia';
        }

        return false;
      },

      votedOn() {
        return this.appState.votes[this.playerName];
      },

      isHost() {
        if (this.currentPlayer) {
          return this.currentPlayer.is_host;
        }

        return false;
      },

      canShowStartButton() {
        return this.isHost && this.appState.is_ready_to_start;
      },

      canShowProgressButton() {
        return this.isHost && (this.appState.state.id === 'day_results' || this.appState.state.id === 'night_results');
      },

      api() {
        return new ApiClient({ pathPrefix: 'http://127.0.0.1:5000/' });
      },
    },

    methods: {
      setState(newState) {
        if (newState.version > this.appState.version) {
          // console.log("this.isHost = ", this.isHost);
          // console.log("this.appState.state.id = ", this.appState.state.id);
          // console.log("newState.state.id = ", newState.state.id);
          if (this.isHost && this.appState.state.id !== newState.state.id) {
            notifyNewState(newState);
          }

          this.appState = newState;
        }
      },

      hasVotedOn(votee) {
        return this.appState.votes[this.playerName] === votee.name;
      },

      canVoteOn(player) {
        if (this.appState.state.id === 'night_voting' && this.currentPlayer.character === 'civil') {
          return false;
        }
        if (!this.currentPlayer.is_alive || !player.is_alive) {
          return false;
        }
        return this.currentPlayer !== player;
      },

      startPolling() {
        setInterval(this.loadState.bind(this), 5000);
      },

      async playAgain() {
        try {
          let json = await this.api.restartTown({
            townSlug: this.appState.slug
          });

          this.setState(json);
        } catch (e) {
          console.error('error =', e);
          window.history.pushState({}, null, '/');
        }
      },

      async loadState() {
        try {
          let json = await this.api.getTown({
            townSlug: this.appState.slug
          });

          this.setState(json);
        } catch (e) {
          console.error('error =', e);
          window.history.pushState({}, null, '/');
        }
      },

      async createTown() {
        let json = await this.api.createTown({
          townSlug: this.appState.slug,
          playerName: this.playerName
        });
        console.log("json = ", json);

        this.setState(json);
        window.history.pushState({}, null, `/towns/${this.appState.slug}`);
        this.startPolling();
      },

      async joinTown() {
        let json = await this.api.joinTown({
          playerName: this.playerName,
          townSlug: this.appState.slug
        });

        this.setState(json);
        window.history.pushState({}, null, `/towns/${this.appState.slug}`);
      },

      async startGame() {
        let json = await this.api.startGame({
          townSlug: this.appState.slug
        });

        this.setState(json);
      },

      async vote(votee) {
        let json = await this.api.createVote({
          townSlug: this.appState.slug,
          voteeName: votee.name,
          voterName: this.currentPlayer.name
        });

        this.setState(json);
      },

      async progressState() {
        let json = await this.api.progressState({
          townSlug: this.appState.slug
        });

        this.setState(json);
      },
    },

    watch: {
      playerName(name) {
        localStorage.playerName = name;
      }
    }
  });
}

document.addEventListener('DOMContentLoaded', init);

export default app;
