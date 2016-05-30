function rest() {
  return new RestClient();
}

function RestClient(){
  this.urlRoot = "http://localhost:3000";
}

RestClient.prototype.get = function(resource, data){
  return this.sendRequest("get", resource, data);
};

RestClient.prototype.post = function(resource, data){
  return this.sendRequest("post", resource, data);
};

RestClient.prototype.put = function(resource, data){
  return this.sendRequest("put", resource, data);
};

RestClient.prototype.delete = function(resource, data){
  return this.sendRequest("delete", resource, data);
};

RestClient.prototype.sendRequest = function(method, resource, data){
  var self = this;
  return new Promise(function(resolve, reject){

    if(!resource.match(/^http/)) {
      resource = self.urlRoot + resource;
    }

    $.ajax({
      beforeSend: function(xhr){
        if(data) {
          xhr.setRequestHeader('Content-Type', 'application/json');
        }
      },
      url: resource,
      type: method,
      data: JSON.stringify(data)
    })
    .then(resolve)
    .fail(reject);
  });
};

const GITHUB_API_URL_BASE = "https://api.github.com";


var routes = {

  repos: {
    index: function(params){
      rest().get(GITHUB_API_URL_BASE+"/users/"+params.currentUser.login+"/repos?sort=updated").then(function(data){
        if(!data.length) {
          $("#list-content").append("<div class='col-md-12'>No issues</div>");
          return;
        }

        var template = $("#common-list-row").html();
        var compiled = _.template(template);

        var html = data.map(function(d){
          return compiled(d);
        })
        .join("\n");

        $("#list-content").append(html);
      })
      .catch(function(err){
        const json = JSON.parse(err.responseText);
        $.notify(json.message);
        console.error(err);
      });
    },
  },

  issues: {
    index: function(params){
      rest().get(GITHUB_API_URL_BASE+"/repos/"+params.owner+"/"+params.repo+"/issues").then(function(data){
        if(!data.length) {
          $("#list-content").append("<div class='col-md-12'>No issues</div>");
          return;
        }

        var template = $("#common-list-row").html();
        var compiled = _.template(template);

        var html = data.map(function(d){
          return compiled(d);
        })
        .join("\n");

        $("#list-content").append(html);
      })
      .catch(function(err){
        const json = JSON.parse(err.responseText);
        $.notify(json.message);
        console.error(err);
      });
    },

    show: function(params){

      function render(data){
        if(!_.isArray(data)) {
          data = [data];
        }

        var template = $("#issue-comment-row").html();
        var compiled = _.template(template);

        var html = data.map(function(d){
          return compiled(d);
        })
        .join("\n");
        $("#list-content").append(html);
      }

      rest().get(GITHUB_API_URL_BASE+"/repos/"+params.owner+"/"+params.repo+"/issues/"+params.number).then(function(data){
        return rest().get(data.comments_url).then(render);
      })
      .catch(function(err){
        const json = JSON.parse(err.responseText);
        $.notify(json.message);
        console.error(err);
      });

      var query = {
        owner: params.owner,
        repo: params.repo,
        number: params.number,
      };

      const queryString = _.map(query, function(v, k){
        return k+"="+v;
      }).join("&");

      var ws = new WebSocket('ws://localhost:3000/ws/chat?'+queryString);

      ws.onopen = function() {
        console.log('Connected');
      };

      ws.onmessage = function(evt) {
        var data = JSON.parse(evt.data);
        switch(data.event) {
          case "comment":
            render(data.data);
            break;
          case "error":
            if(data.data.message) {
              $.notify(data.data.message);
            }
            break;
        }
      };

      ws.emit = function(event, data){
        const wrapperData = {
          event: event,
          data: data
        };
        ws.send(JSON.stringify(wrapperData));
      };

      $("#post-comment").click(function(ev){
        ev.preventDefault();

        const message = $("#message").val();
        if(_.isEmpty(message)) {
          return;
        }

        var data = {
          body: message,
          user: params.currentUser
        };

        ws.emit("comment", data);
        render(data);
      });
    },

    new: function(params){
      $("#post").click(function(){
        const title = $("#title").val();
        const body = $("#message").val();

        const data = {
          title: title,
          body: body,
        };
        rest().post("/api/"+params.owner+"/"+params.repo+"/issues", data).then(function(data){
          $.notify("Successfully created an issue", "success");
          setTimeout(function(){
            location.href="/issues/"+params.owner+"/"+params.repo;
          }, 500);
        })
        .catch(function(err){
          const json = JSON.parse(err.responseText);
          $.notify(json.message);
          console.error(err);
        });
      });
    }
  },
};
